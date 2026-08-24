{
  nixpkgs,
  home-manager,
  nix-darwin,
  nix-flatpak,
  claude-code,
  dms,
  nixpkgs-stable,
  chevron,
  sak,
  sops-nix,
  vpinball-flake,
  ...
}:

let
  # Overlay: exposes pkgs.stable.* for pinning packages to the stable channel
  stableOverlay = system: final: prev: {
    stable = nixpkgs-stable.legacyPackages.${system};
  };

  # Overlay: exposes pkgs.chevron from the chevron flake input
  # (shiprock/chevron, formerly mmichie/plx).
  # Tests disabled: upstream node segment test fails in the Nix sandbox
  # because it assumes no package.json exists in parent directories.
  chevronOverlay = system: final: prev: {
    chevron = (chevron.packages.${system}.default).overrideAttrs { doCheck = false; };
  };

  # Overlay: exposes pkgs.sak from the sak flake input
  sakOverlay = system: final: prev: {
    sak = sak.packages.${system}.default;
  };

  # Overlay: skip pipx's test suite.
  # A newer `packaging` release changed the canonical form of PEP 508
  # direct-reference specifiers ("black @ url" instead of "black@ url"),
  # which breaks hardcoded string assertions in pipx 1.8.0's tests. The
  # built program is unaffected; only checkPhase fails. Remove once the
  # pipx package's tests are fixed upstream.
  pipxOverlay = final: prev: {
    pipx = prev.pipx.overridePythonAttrs (_: {
      doCheck = false;
    });
  };

  # Overlay: exposes pkgs.beads_rust from pre-built binary release
  beadsOverlay = final: prev: {
    beads_rust = final.callPackage ../packages/beads_rust.nix { };
  };

  # Overlay: exposes pkgs.ultimarc-linux (the `umtool` CLI for programming
  # Ultimarc arcade control boards). Consumed by the arcade host.
  ultimarcOverlay = final: prev: {
    ultimarc-linux = final.callPackage ../packages/ultimarc-linux.nix { };
  };

  # Overlay: exposes pkgs.qtpyultimarc (the Python/QML successor to
  # Ultimarc-linux — `ultimarc` CLI + `ultimarc-ui` GUI). Two of its runtime
  # deps are missing from nixpkgs, so they are packaged here and also exposed
  # as pkgs.python-easy-json / pkgs.python-libusb. Consumed by the arcade host.
  qtpyUltimarcOverlay =
    final: prev:
    let
      py = final.python3Packages;
      python-easy-json = py.callPackage ../packages/python-easy-json.nix { };
      # libusb1 = the C library, not python3Packages.libusb1 (python-libusb1).
      python-libusb = py.callPackage ../packages/python-libusb.nix {
        libusb1 = final.libusb1;
      };
    in
    {
      inherit python-easy-json python-libusb;
      qtpyultimarc = py.callPackage ../packages/qtpyultimarc.nix {
        inherit python-easy-json python-libusb;
      };
    };

  # Overlay: exposes pkgs.vpinball from the vpinball-flake input.
  # Only defined on x86_64-linux — the fork's flake outputs do not
  # support darwin or aarch64-linux.
  # Use the vpinball-debug variant so crashes in the binary produce
  # useful stack traces. Exposed as `pkgs.vpinball` so downstream
  # consumers (packages/vpinball-fhs.nix) don't need to care.
  vpinballOverlay =
    system: final: prev:
    if system == "x86_64-linux" then
      {
        vpinball = vpinball-flake.packages.${system}.vpinball-debug;
      }
    else
      { };

  overlays = system: [
    claude-code.overlays.default
    (stableOverlay system)
    (chevronOverlay system)
    (sakOverlay system)
    pipxOverlay
    beadsOverlay
    ultimarcOverlay
    qtpyUltimarcOverlay
    (vpinballOverlay system)
  ];

  # ── Home module sets ─────────────────────────────────────────────────

  # Shared across ALL classes (including servers)
  coreHomeModules = [
    ../modules/home/options.nix
    ../modules/home/user.nix
    ../modules/home/packages-core.nix
    ../modules/home/shell.nix
    ../modules/home/git.nix
    ../modules/home/ssh.nix
  ];

  # Additional home modules for workstation classes (macOS + Linux)
  workstationHomeModules = [
    ../modules/home/packages-dev.nix
    ../modules/home/wezterm.nix
    ../modules/home/opencode.nix
  ];

  # Linux workstation GUI packages
  linuxGuiHomeModules = [
    ../modules/home/packages-linux-gui.nix
    ../modules/home/syncthing.nix
  ];

  # ── Class definitions ────────────────────────────────────────────────

  classConfig = {
    linux-workstation = {
      systemModules = [
        ../modules/nixos/base.nix
        ../modules/nixos/workstation.nix
      ];
      homeModules = coreHomeModules ++ workstationHomeModules ++ linuxGuiHomeModules;
      homeBase = ../hostclass/linux-workstation.nix;
      specialArgs = { inherit dms; };
      hmSharedModules = [ nix-flatpak.homeManagerModules.nix-flatpak ];
    };

    linux-server = {
      systemModules = [
        ../modules/nixos/base.nix
        ../modules/nixos/server.nix
      ];
      homeModules = coreHomeModules;
      homeBase = ../hostclass/linux-server.nix;
      specialArgs = { };
      hmSharedModules = [ ];
    };

    arcade = {
      systemModules = [
        ../modules/nixos/base.nix
        ../modules/nixos/arcade.nix
      ];
      homeModules = coreHomeModules ++ [
        ../modules/home/packages-arcade.nix
        ../modules/home/wezterm.nix
      ];
      homeBase = ../hostclass/arcade.nix;
      specialArgs = { };
      hmSharedModules = [ ];
    };
  };

  # ── Host constructors ────────────────────────────────────────────────

  mkNixosHost =
    {
      hostname,
      username ? "pjl",
      system ? "x86_64-linux",
      class,
      extraModules ? [ ],
      extraHomeModules ? [ ],
    }:
    let
      cc = classConfig.${class};
    in
    nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = cc.specialArgs // {
        inherit username;
      };
      modules = [
        ../hosts/${hostname}/default.nix
      ]
      ++ cc.systemModules
      ++ [
        sops-nix.nixosModules.sops
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            sharedModules = cc.hmSharedModules;
            useGlobalPkgs = true;
            useUserPackages = true;
            users.${username} = {
              imports = cc.homeModules ++ [ cc.homeBase ] ++ extraHomeModules;
            };
          };
        }
        (
          { pkgs, ... }:
          {
            nixpkgs.overlays = overlays system;
            environment.systemPackages = [ pkgs.claude-code ];
          }
        )
      ]
      ++ extraModules;
    };

  mkDarwinHost =
    {
      hostname,
      username ? "pjl",
      system ? "aarch64-darwin",
      extraModules ? [ ],
      extraHomeModules ? [ ],
    }:
    nix-darwin.lib.darwinSystem {
      inherit system;
      specialArgs = {
        inherit username;
      };
      modules = [
        ../hosts/${hostname}/default.nix
        ../modules/darwin/base.nix
        ../modules/darwin/homebrew.nix
        home-manager.darwinModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "hm-backup";
            users.${username} = {
              imports =
                coreHomeModules
                ++ workstationHomeModules
                ++ [ ../hostclass/darwin-workstation.nix ]
                ++ extraHomeModules;
            };
          };
        }
        (
          { pkgs, ... }:
          {
            nixpkgs.overlays = overlays system;
          }
        )
      ]
      ++ extraModules;
    };

in
{
  inherit mkNixosHost mkDarwinHost;
}

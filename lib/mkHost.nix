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

  # Overlay: fix mame's build by compiling the SDL3 OSD against the real sdl3
  # library instead of the SDL2 compat shim. MAME 0.286+ switched the default
  # OSD to sdl3 on macOS (and upstream is unifying every platform on sdl3), but
  # nixpkgs still wires up SDL2/sdl2-compat — so the Darwin build fails with
  # "'SDL3/SDL.h' file not found" and the Linux build only works by accident.
  # Mirrors the three changes in nixpkgs PR #495586 (open/unmerged as of
  # 2026-06): swap SDL2 -> sdl3 inputs, force OSD=sdl3, and patch the macOS
  # sw_vers call in sdl3.lua. Remove this once that PR lands. See nixpkgs
  # issue #495438.
  mameOverlay = final: prev: {
    mame = prev.mame.overrideAttrs (old: {
      buildInputs = (builtins.filter (p: p != final.SDL2 && p != final.SDL2_ttf) old.buildInputs) ++ [
        final.sdl3
        final.sdl3-ttf
      ];
      makeFlags = old.makeFlags ++ [ "OSD=sdl3" ];
      postPatch =
        old.postPatch
        + final.lib.optionalString final.stdenv.hostPlatform.isDarwin ''
          substituteInPlace scripts/src/osd/sdl3.lua --replace-fail \
            'backtick("sw_vers -productVersion")' \
            "os.getenv('MACOSX_DEPLOYMENT_TARGET') or '$darwinMinVersion'"
        '';
    });
  };

  overlays = system: [
    claude-code.overlays.default
    (stableOverlay system)
    (chevronOverlay system)
    (sakOverlay system)
    pipxOverlay
    beadsOverlay
    (vpinballOverlay system)
    mameOverlay
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

{
  nixpkgs,
  home-manager,
  nix-darwin,
  nix-flatpak,
  claude-code,
  dms,
  nixpkgs-stable,
  plx,
  ...
}:

let
  # Overlay: exposes pkgs.stable.* for pinning packages to the stable channel
  stableOverlay = system: final: prev: {
    stable = nixpkgs-stable.legacyPackages.${system};
  };

  # Overlay: exposes pkgs.plx from the plx flake input
  plxOverlay = system: final: prev: {
    plx = plx.packages.${system}.default;
  };

  overlays = system: [
    claude-code.overlays.default
    (stableOverlay system)
    (plxOverlay system)
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
  ];

  # Linux workstation GUI packages
  linuxGuiHomeModules = [
    ../modules/home/packages-linux-gui.nix
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
      modules = [
        ../hosts/${hostname}/default.nix
        ../modules/darwin/base.nix
        home-manager.darwinModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
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

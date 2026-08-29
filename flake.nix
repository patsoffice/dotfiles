{
  description = "Pat's NixOS configuration";

  nixConfig = {
    extra-substituters = [ "https://patsoffice.cachix.org" ];
    extra-trusted-public-keys = [
      "patsoffice.cachix.org-1:C1fBDvGbwf7jjrcbCTT6epSnlq7IrZyYN/5H3pb+GtQ="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-26.05";
    claude-code.url = "github:sadjow/claude-code-nix?ref=v2.1.251"; # pin exact version

    home-manager = {
      # Tracks master, which is what pairs with nixpkgs/nixos-unstable (now
      # 26.11-pre). There is no release-26.11 branch yet, and release-26.05 is
      # behind nixpkgs: it still calls the deprecated stdenv.isLinux /
      # stdenv.isDarwin (fixed on master, never backported) and trips the
      # home-manager/nixpkgs version-mismatch warning. Repin to
      # release-26.11 once that branch exists.
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-flatpak = {
      url = "github:gmodena/nix-flatpak/?ref=latest";
    };

    chevron = {
      url = "github:shiprock/chevron"; # formerly mmichie/plx
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sak = {
      url = "github:patsoffice/sak";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vpinball-flake = {
      url = "github:patsoffice/vpinball-flake/experimental";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      chevron,
      sak,
      ...
    }@inputs:
    let
      helpers = import ./lib/mkHost.nix inputs;
    in
    {
      # ── NixOS hosts ───────────────────────────────────────────────────
      nixosConfigurations = {
        heather-desktop = helpers.mkNixosHost {
          hostname = "heather-desktop";
          class = "linux-server";
          extraModules = [
            inputs.disko.nixosModules.disko
          ];
        };
        pjl-desktop = helpers.mkNixosHost {
          hostname = "pjl-desktop";
          class = "linux-workstation";
        };
        nas0 = helpers.mkNixosHost {
          hostname = "nas0";
          class = "linux-server";
          extraModules = [
            inputs.disko.nixosModules.disko
          ];
        };
        pinball = helpers.mkNixosHost {
          hostname = "pinball";
          class = "arcade";
          extraModules = [
            inputs.disko.nixosModules.disko
          ];
          extraHomeModules = [
            ./hosts/pinball/home.nix
          ];
        };
        arcade = helpers.mkNixosHost {
          hostname = "arcade";
          class = "arcade";
          extraModules = [
            inputs.disko.nixosModules.disko
          ];
        };
      };

      # ── macOS hosts ───────────────────────────────────────────────────
      darwinConfigurations = {
        pjl-mbpro = helpers.mkDarwinHost {
          hostname = "pjl-mbpro";
        };
      };

      # ── Packages ───────────────────────────────────────────────────
      packages = {
        aarch64-darwin.chevron = (chevron.packages.aarch64-darwin.default).overrideAttrs {
          doCheck = false;
        };
        aarch64-linux.chevron = (chevron.packages.aarch64-linux.default).overrideAttrs { doCheck = false; };
        x86_64-linux.chevron = (chevron.packages.x86_64-linux.default).overrideAttrs { doCheck = false; };
        aarch64-darwin.sak = sak.packages.aarch64-darwin.default;
        aarch64-linux.sak = sak.packages.aarch64-linux.default;
        x86_64-linux.sak = sak.packages.x86_64-linux.default;
        x86_64-linux.mame-nodelog =
          nixpkgs.legacyPackages.x86_64-linux.callPackage ./packages/mame-nodelog.nix
            { };
      };

      # ── Formatter ────────────────────────────────────────────────────
      formatter = {
        aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixfmt-tree;
        aarch64-linux = nixpkgs.legacyPackages.aarch64-linux.nixfmt-tree;
        x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-tree;
      };
    };
}

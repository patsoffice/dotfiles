{
  description = "Pat's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11";
    claude-code.url = "github:sadjow/claude-code-nix?ref=v2.1.71"; # pin exact version

    home-manager = {
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

    plx = {
      url = "github:mmichie/plx";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      plx,
      ...
    }@inputs:
    let
      helpers = import ./lib/mkHost.nix inputs;
    in
    {
      # ── NixOS hosts ───────────────────────────────────────────────────
      nixosConfigurations = {
        nixos-testing = helpers.mkNixosHost {
          hostname = "nixos-testing";
          class = "linux-workstation";
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
        aarch64-darwin.plx = plx.packages.aarch64-darwin.default;
        aarch64-linux.plx = plx.packages.aarch64-linux.default;
        x86_64-linux.plx = plx.packages.x86_64-linux.default;
      };

      # ── Formatter ────────────────────────────────────────────────────
      formatter = {
        aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixfmt-tree;
        aarch64-linux = nixpkgs.legacyPackages.aarch64-linux.nixfmt-tree;
        x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-tree;
      };
    };
}

{ lib, ... }:

{
  options.my = {
    user.name = lib.mkOption {
      type = lib.types.str;
      default = "pjl";
      description = "Primary username";
    };

    user.stateVersion = lib.mkOption {
      type = lib.types.str;
      default = "25.11";
      description = "Home-manager state version";
    };

    dotfilesPath = lib.mkOption {
      type = lib.types.str;
      description = "Path to dotfiles configs directory";
    };
  };
}

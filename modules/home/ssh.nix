{ config, ... }:

{
  # SSH config
  home.file.".ssh/config".source =
    config.lib.file.mkOutOfStoreSymlink "${config.my.dotfilesPath}/ssh/config";

  # 1Password SSH public keys — OpenSSH 10.2+ requires .pub files to offer agent keys
  home.file.".ssh/id_ed25519.pub".text =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJqxC/bil4Nnlob47rm5wahder21ha6urx1J7xVfm71F Personal SSH key\n";
  home.file.".ssh/id_rsa_lightsail.pub".text =
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCyRr6Nag3jZAkhW8rIKRNt5MKgiCS7rf+1B/n/lBHuyUj0yab186bNnrnRtS8yVBy1OqW6skX5WRIwpl6H8Oc9nPpdNEY7ttT5Xd+UEzjpreS8GlJhcJz2dT4nS1Iia1Fc2WsC61uYYATzhoWj3qPyO3efKIzj0JoBQyFyeqey8VVQjRW9Mb4xh3opIju5FmxyIm+sTJEKb5PWBiNAzZEAIgv2hapvhU3E646RbEfLHf74B8muZMBUrabWooVAAPN4N2VtwjAGgjlObqeHBU0JcZQ2Hs82JeTmBE+1P2afbrwU0Tg0i2WfWkm18zuLvNSkY+szEtCrc87yu8H3bsrjguF0k3YcnrMOcDMVij2jA/nzt7DT3uctRvJRGsZ2R6kmZGnYWP2fuhCmOh33PXjxD1zhWyFWUX9z1dTD2AvfvhJO9dBfAgmWsBiKKLq4xTjvUw/GBBF+iI4ZWHyB81EwRR7LbXNW41YeG3dBRPmmlWR5/JhQLyCXPE6rG/bxN+5ny3T6RQ27OuxNFL9UfzjR6SHCnNS7UgmI91CC1Rg/Mtsv8tI1gVdI0p2RER6IXQeMiVxH37LC0RXOyBx7UIDfbjmDddIg4iMDMjK17+mdHijuDmvDMxLO+PImeOVXesBd+9NpD0FzjCTb5bNOk8cv8kKMMaDhYPYSV6ZISiK5Vw== id_rsa_lightsail\n";
  home.file.".ssh/id_rsa_github.pub".text =
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDInsWAVOT8weHf3ifFEWVytqZbH4SilsKWV96o409nDqvwttpLu4YQOoDSmgtpAQR7Ewdkm0YTryWqk+RiddL7bxGuDj8+MsKFFf9wTjk/djWw3KmwIjVf98T7Y4tqnrfASX6tIXnKLY+LvkYZwhxsF0+AWaISsD98sthSyRN1tn8SOoJodA9Mc4NQDOxOEABUzRGbyf4OFRh9D9oYuFP2qkOXl6SijjeDG2SEXfBcXz52K4L4Kz6iEpdpXsTQZtmqhuwktYD14+6Y5zMFXefy3oH/J4FPlGNV86O1gbVh4xfEdpa+30EgiX3ZpLC3P8GhG38dHerwSH9+29QWJk4L GitHub SSH Key\n";
}

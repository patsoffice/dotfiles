{ config, pkgs, ... }:

{
  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    # ── Core CLI & Shell ───────────────────────────────────────────────
    coreutils
    curl
    fd
    findutils
    fzf
    gh
    git
    git-filter-repo
    gnupg
    inetutils
    jq
    moreutils
    pv
    ripgrep
    sd
    sops
    watch
    wget
    xh
    yq
    zoxide
    zsh-completions

    # ── Shell Experience ───────────────────────────────────────────────
    bat
    btop
    delta
    difftastic
    duf
    dust
    eza
    gping
    htop
    procs
    vivid

    # ── Editors ────────────────────────────────────────────────────────
    neovim

    # ── Terminals ─────────────────────────────────────────────────────
    tmux

    # ── Infrastructure & Cloud ─────────────────────────────────────────
    ansible
    awscli2
    docker-compose
    kind
    kubectl
    kubernetes-helm
    minikube
    opentofu
    stern

    # ── Network & Security ─────────────────────────────────────────────
    doggo
    iftop
    ipmitool
    smartmontools
    keybase
    mtr
    nmap
    socat
    sshpass
    sshuttle
    sslscan
    #stable.samba
    wireshark-cli

    # ── Prompt Segments ───────────────────────────────────────────────
    plx

    # ── Misc CLI ───────────────────────────────────────────────────────
    direnv
    just
    dos2unix
    glow
    hexyl
    mmv-go
    nix-direnv
    nvd
    p7zip
    pstree
    rclone
    restic
    tealdeer
    transcrypt
    tree
    xz
  ];
}

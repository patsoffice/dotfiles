{ config, lib, pkgs, ... }:

{
  programs.home-manager.enable = true;

  home.packages =
    with pkgs;
    [
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
      prettyping
      socat
      sshpass
      sshuttle
      sslscan
      wireshark-cli

      # ── Prompt Segments ───────────────────────────────────────────────
      chevron

      # ── Misc CLI ───────────────────────────────────────────────────────
      beads_rust
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
    ]
    # macOS ships its own ping/telnet/ftp/hostname at /sbin and /usr/bin.
    # Installing inetutils here would shadow them with non-setuid versions.
    ++ lib.optionals stdenv.isLinux [
      inetutils
      samba # provides smbclient
    ];
}

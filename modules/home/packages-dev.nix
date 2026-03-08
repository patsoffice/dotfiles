{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # ── Editors ────────────────────────────────────────────────────────
    vscode

    # ── Terminals ─────────────────────────────────────────────────────
    wezterm

    # ── Development — Go ───────────────────────────────────────────────
    delve
    go
    gofumpt
    golangci-lint
    gopls

    # ── Development — Rust ─────────────────────────────────────────────
    cargo
    clippy
    rust-analyzer
    rustc
    rustfmt

    # ── Development — Python ───────────────────────────────────────────
    pipx
    pyright
    ruff
    uv

    # ── Development — C/C++ ────────────────────────────────────────────
    clang-tools # includes clang-format
    cmake

    # ── Development — Other ────────────────────────────────────────────
    hyperfine
    just
    lefthook
    pre-commit
    shellcheck
    tokei
    watchexec

    # ── Media & Documents ──────────────────────────────────────────────
    ffmpeg
    imagemagick
    pandoc
    texliveSmall

    # ── Misc ───────────────────────────────────────────────────────────
    asciinema
    bandwhich
    figlet
    gum
    toilet
    vhs
  ];
}

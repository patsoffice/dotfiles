{
  config,
  pkgs,
  lib,
  ...
}:

{
  home.packages =
    with pkgs;
    [
      # ── Editors (vscode on Darwin via Homebrew cask) ──────────────────
    ]
    ++ lib.optionals (!pkgs.stdenv.isDarwin) [
      vscode
    ]
    ++ [

      # ── Terminals ─────────────────────────────────────────────────────
      wezterm

      # ── Development — Go ───────────────────────────────────────────────
      delve
      go
      gofumpt
      golangci-lint
      gopls

      # ── Development — Rust (skipped on Darwin; managed by rustup) ──────
    ]
    ++ lib.optionals (!pkgs.stdenv.isDarwin) [
      cargo
      clippy
      rust-analyzer
      rustc
      rustfmt
    ]
    ++ [
      # ── Development — Python ───────────────────────────────────────────
      pipx
      pyright
      ruff
      uv

      # ── Development — C/C++ ────────────────────────────────────────────
      clang-tools # includes clang-format
      cmake

      # ── Development — Infra ─────────────────────────────────────────────
      talosctl

      # ── Development — Other ────────────────────────────────────────────
      hyperfine
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

      # ── LLM Tools ──────────────────────────────────────────────────────
      sak

      # ── Misc ───────────────────────────────────────────────────────────
      asciinema
      bandwhich
      figlet
      gum
      toilet
      vhs
    ];
}

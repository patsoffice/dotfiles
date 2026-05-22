{
  lib,
  stdenvNoCC,
  fetchurl,
}:

let
  version = "0.2.11";

  # Release assets dropped the "v" prefix from the filename as of 0.2.x
  # (br-${version}-…); the release tag in the path is still v${version}.
  sources = {
    aarch64-darwin = {
      url = "https://github.com/Dicklesworthstone/beads_rust/releases/download/v${version}/br-${version}-darwin_arm64.tar.gz";
      hash = "sha256-15du3I6GEmhqOdUd3n3+031fSr+YpeoU4mpSwOZ2580=";
    };
    x86_64-linux = {
      url = "https://github.com/Dicklesworthstone/beads_rust/releases/download/v${version}/br-${version}-linux_amd64.tar.gz";
      hash = "sha256-OQe5aBIsmYLjmCLF9Wlk94bM8vPs38MpHoZT7KOd6c8=";
    };
  };

  src = fetchurl sources.${stdenvNoCC.hostPlatform.system};
in

stdenvNoCC.mkDerivation {
  pname = "beads_rust";
  inherit version src;

  sourceRoot = ".";

  installPhase = ''
    install -Dm755 br $out/bin/br
  '';

  meta = {
    description = "Agent-first issue tracker (SQLite + JSONL)";
    homepage = "https://github.com/Dicklesworthstone/beads_rust";
    license = lib.licenses.mit;
    mainProgram = "br";
    platforms = builtins.attrNames sources;
  };
}

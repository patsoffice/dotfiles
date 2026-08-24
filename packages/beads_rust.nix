{
  lib,
  stdenvNoCC,
  fetchurl,
}:

let
  # br >= 0.2.20 requires DB schema 17 and will only migrate from 13-16, so a
  # database older than that needs br 0.2.19 (the last release that migrates
  # schema 4/11 up to 16) run against it once before this version can open it.
  # All our .beads DBs were carried across on 2026-08-24; a restored-from-
  # backup old DB would need that stepping stone again.
  version = "0.4.0";

  # Release assets dropped the "v" prefix from the filename as of 0.2.x
  # (br-${version}-…); the release tag in the path is still v${version}.
  sources = {
    aarch64-darwin = {
      url = "https://github.com/Dicklesworthstone/beads_rust/releases/download/v${version}/br-${version}-darwin_arm64.tar.gz";
      hash = "sha256-VD9BCvhE08FqnYUG5lsH4NfLXlayDDewx7gwCcxJl1c=";
    };
    x86_64-linux = {
      url = "https://github.com/Dicklesworthstone/beads_rust/releases/download/v${version}/br-${version}-linux_amd64.tar.gz";
      hash = "sha256-63+XodmRmHBOegpwuOQaSSguMluxFpuz+LicmXm9Vjo=";
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

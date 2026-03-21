{
  lib,
  stdenvNoCC,
  fetchurl,
}:

let
  version = "0.1.30";

  sources = {
    aarch64-darwin = {
      url = "https://github.com/Dicklesworthstone/beads_rust/releases/download/v${version}/br-v${version}-darwin_arm64.tar.gz";
      hash = "sha256-EBvdiTSgjLncDRyevolxPwUVnofctiyAbUXGWWDzqLI=";
    };
    x86_64-linux = {
      url = "https://github.com/Dicklesworthstone/beads_rust/releases/download/v${version}/br-v${version}-linux_amd64.tar.gz";
      hash = "sha256-cfYrDbeCIt2//Sy0UwB3ddpUyxyav9dTcPSex4GqLhA=";
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

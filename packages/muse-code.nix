{
  lib,
  stdenvNoCC,
  fetchurl,
}:

let
  # Upstream's installer drops a self-updating launcher in ~/.local/bin that
  # pulls the binary at runtime; this skips it and pins the binary directly.
  # To bump: read `version` from
  #   https://api.meta.ai/muse-code/channels/muse-stable
  # then take each platform's sha256 from that release's manifest.json
  # (`nix hash convert --hash-algo sha256 --to sri <hex>`).
  version = "1.4.14-R7309.1";

  artifact =
    file:
    "https://lookaside.facebook.com/lookaside/muse/download/?channel=muse&version=${version}&file=${file}";

  # The binaries are statically linked, so no patchelf is needed on NixOS.
  sources = {
    aarch64-darwin = {
      url = artifact "muse-aarch64-macos";
      hash = "sha256-HJYRRAisvq3pqPt547RCXltk1QQlk4VorvAb3ATOLgM=";
    };
    aarch64-linux = {
      url = artifact "muse-aarch64-linux";
      hash = "sha256-PcObj6JvmWPMIDjylmwJMu1aOfD577OcwCZqJhy7z3Y=";
    };
    x86_64-darwin = {
      url = artifact "muse-x86-macos";
      hash = "sha256-baWhLTKYr7pFr+ySn8OFtRYITtKOlQSuKTVNvN/ECJ0=";
    };
    x86_64-linux = {
      url = artifact "muse-x86-linux";
      hash = "sha256-CAmqx8tY0Y9QIrbQXgKqGXRoPA7EMOXwTSW2DtF94to=";
    };
  };

  # The URL's last path segment is a query string, so name the file explicitly.
  src = fetchurl (sources.${stdenvNoCC.hostPlatform.system} // { name = "muse-${version}"; });
in

stdenvNoCC.mkDerivation {
  pname = "muse-code";
  inherit version src;

  dontUnpack = true;

  installPhase = ''
    install -Dm755 $src $out/bin/muse
  '';

  meta = {
    description = "Meta's terminal coding agent";
    homepage = "https://dev.meta.ai/products/muse-code";
    # No license is published alongside the binaries.
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "muse";
    platforms = builtins.attrNames sources;
  };
}

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
  version = "1.4.4-R5419.1";

  artifact =
    file:
    "https://lookaside.facebook.com/lookaside/muse/download/?channel=muse&version=${version}&file=${file}";

  # The binaries are statically linked, so no patchelf is needed on NixOS.
  sources = {
    aarch64-darwin = {
      url = artifact "muse-aarch64-macos";
      hash = "sha256-f3CEFCB9FmWFi6pu8u8PXGnHJ/WzwAJD+jmML11bXMA=";
    };
    aarch64-linux = {
      url = artifact "muse-aarch64-linux";
      hash = "sha256-vBGWeTknuq8HU16RmdBT6jdUs7xljaH+wT038InMzRE=";
    };
    x86_64-darwin = {
      url = artifact "muse-x86-macos";
      hash = "sha256-2I/J2hTP8GpfQOIJ6MNQJFEynY1RQ8FHu3t2CSBNGqI=";
    };
    x86_64-linux = {
      url = artifact "muse-x86-linux";
      hash = "sha256-z8nQaEQf9GA2rWu/MN15QEOyW377aWSMksAizPZffRk=";
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

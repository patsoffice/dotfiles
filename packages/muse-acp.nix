{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:

let
  version = "0.18.0";

  # No "v" prefix in the filename; the release tag in the path keeps it.
  # .sha256 sidecar files next to each asset hold the expected hex digest
  # (`nix hash convert --hash-algo sha256 --to sri <hex>`).
  sources = {
    aarch64-darwin = {
      url = "https://github.com/BrokkAi/muse-acp/releases/download/v${version}/muse-acp-v${version}-aarch64-apple-darwin.tar.gz";
      hash = "sha256-zW4YpVMI2vX/nzOfVxKeyrD4NnD0WWb4rBXNwvihEVM=";
    };
    aarch64-linux = {
      url = "https://github.com/BrokkAi/muse-acp/releases/download/v${version}/muse-acp-v${version}-aarch64-unknown-linux-gnu.tar.gz";
      hash = "sha256-16DG7ikDmAlBTeSVSaSUbKBkCX0LHZxh1qxWeDKkFpo=";
    };
    x86_64-darwin = {
      url = "https://github.com/BrokkAi/muse-acp/releases/download/v${version}/muse-acp-v${version}-x86_64-apple-darwin.tar.gz";
      hash = "sha256-ZqN+XRaurdfLl683km0ZG0dtrlbuQIcEKuo8kaXFEY4=";
    };
    x86_64-linux = {
      url = "https://github.com/BrokkAi/muse-acp/releases/download/v${version}/muse-acp-v${version}-x86_64-unknown-linux-gnu.tar.gz";
      hash = "sha256-92kHLiD8v4bEiUgUg5o71P3R2bgk5IDamJFnmz7nmKM=";
    };
  };

  src = fetchurl sources.${stdenv.hostPlatform.system};
in

stdenv.mkDerivation {
  pname = "muse-acp";
  inherit version src;

  # The Linux binaries are dynamically linked (gnu target), so the
  # interpreter and libgcc need rewriting for the Nix store. No-op on
  # Darwin (Mach-O), where the hook is skipped entirely.
  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    autoPatchelfHook
  ];
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    stdenv.cc.cc.lib
  ];

  installPhase = ''
    install -Dm755 muse-acp $out/bin/muse-acp
  '';

  meta = {
    description = "ACP adapter for Meta's Muse Code (Zed/JetBrains integration)";
    homepage = "https://github.com/BrokkAi/muse-acp";
    license = lib.licenses.asl20;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "muse-acp";
    platforms = builtins.attrNames sources;
  };
}

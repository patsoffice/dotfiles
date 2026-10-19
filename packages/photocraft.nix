{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  wayland,
  libxkbcommon,
  vulkan-loader,
}:

let
  version = "0.10.0";

  # storytold/photocraft — open-source photo editor in pure Rust.
  # Linux tarballs ship a .sha256 sidecar in SHA256SUMS.txt next to the
  # release assets (`nix hash convert --hash-algo sha256 --to sri <hex>`).
  # Linux only for now: upstream's macOS builds are DMGs, and macOS
  # support is a later step.
  sources = {
    aarch64-linux = {
      url = "https://github.com/storytold/photocraft/releases/download/v${version}/photocraft-${version}-linux-aarch64.tar.gz";
      hash = "sha256-gpeA0zHmRD3fG62pMu0H4OncVBshOydfPDoyCWB7x8c=";
    };
    x86_64-linux = {
      url = "https://github.com/storytold/photocraft/releases/download/v${version}/photocraft-${version}-linux-x86_64.tar.gz";
      hash = "sha256-xdRVeF2cLq9pW/jmMnxNbSOjnduVamEU8MW2Qyb5hOE=";
    };
  };

  src = fetchurl sources.${stdenv.hostPlatform.system};
in

stdenv.mkDerivation {
  pname = "photocraft";
  inherit version src;

  # The release binaries are dynamically linked (gnu target), so the
  # interpreter and libgcc need rewriting for the Nix store.
  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    autoPatchelfHook
    makeWrapper
  ];
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    stdenv.cc.cc.lib
    wayland
    libxkbcommon
    vulkan-loader
  ];

  installPhase = ''
    install -Dm755 bin/photocraft $out/bin/photocraft
    install -Dm755 bin/photocraft-cli $out/bin/photocraft-cli
  '';

  # winit dlopens libwayland-client at runtime (likewise xkbcommon for
  # keyboard input and the Vulkan loader for wgpu rendering), so expose
  # them through the wrapper — autoPatchelfHook only sees linked libs.
  postFixup = ''
    wrapProgram $out/bin/photocraft \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ wayland libxkbcommon vulkan-loader ]}"
    wrapProgram $out/bin/photocraft-cli \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ wayland libxkbcommon vulkan-loader ]}"
  '';

  meta = {
    description = "Open-source photo editor";
    homepage = "https://github.com/storytold/photocraft";
    license = with lib.licenses; [
      mit
      asl20
    ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "photocraft";
    platforms = builtins.attrNames sources;
  };
}

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
  version = "0.9.0";

  # storytold/pdfcraft — open-source PDF reader and editor in pure Rust.
  # Linux tarballs ship a .sha256 sidecar in SHA256SUMS.txt next to the
  # release assets (`nix hash convert --hash-algo sha256 --to sri <hex>`).
  # Linux only for now: upstream's macOS builds are DMGs, and macOS
  # support is a later step.
  sources = {
    aarch64-linux = {
      url = "https://github.com/storytold/pdfcraft/releases/download/v${version}/pdfcraft-${version}-linux-aarch64.tar.gz";
      hash = "sha256-fIMDXr5cbcEGSedvUgIBesLaDeSPJNt/h/yvCa30Jhk=";
    };
    x86_64-linux = {
      url = "https://github.com/storytold/pdfcraft/releases/download/v${version}/pdfcraft-${version}-linux-x86_64.tar.gz";
      hash = "sha256-/199o2oQiTQOP9umlrKGzDF6yPBwXMjETBxJ2cpMVOA=";
    };
  };

  src = fetchurl sources.${stdenv.hostPlatform.system};
in

stdenv.mkDerivation {
  pname = "pdfcraft";
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
    install -Dm755 bin/pdfcraft $out/bin/pdfcraft
    install -Dm755 bin/pdfcraft-cli $out/bin/pdfcraft-cli
  '';

  # winit dlopens libwayland-client at runtime (likewise xkbcommon for
  # keyboard input and the Vulkan loader for wgpu rendering), so expose
  # them through the wrapper — autoPatchelfHook only sees linked libs.
  postFixup = ''
    wrapProgram $out/bin/pdfcraft \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ wayland libxkbcommon vulkan-loader ]}"
    wrapProgram $out/bin/pdfcraft-cli \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ wayland libxkbcommon vulkan-loader ]}"
  '';

  meta = {
    description = "Open-source PDF reader and editor";
    homepage = "https://github.com/storytold/pdfcraft";
    license = with lib.licenses; [
      mit
      asl20
    ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "pdfcraft";
    platforms = builtins.attrNames sources;
  };
}

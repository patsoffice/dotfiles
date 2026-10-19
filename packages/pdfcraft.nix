{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  undmg,
  unzip,
  wayland,
  libxkbcommon,
  vulkan-loader,
}:

let
  version = "0.9.0";

  # storytold/pdfcraft — open-source PDF reader and editor in pure Rust.
  # Release assets ship a .sha256 sidecar in SHA256SUMS.txt / a GitHub
  # digest next to each asset (`nix hash convert --hash-algo sha256
  # --to sri <hex>`). macOS ships a signed universal DMG plus a separate
  # CLI zip instead of the Linux tarball.
  sources = {
    aarch64-linux = {
      url = "https://github.com/storytold/pdfcraft/releases/download/v${version}/pdfcraft-${version}-linux-aarch64.tar.gz";
      hash = "sha256-fIMDXr5cbcEGSedvUgIBesLaDeSPJNt/h/yvCa30Jhk=";
    };
    x86_64-linux = {
      url = "https://github.com/storytold/pdfcraft/releases/download/v${version}/pdfcraft-${version}-linux-x86_64.tar.gz";
      hash = "sha256-/199o2oQiTQOP9umlrKGzDF6yPBwXMjETBxJ2cpMVOA=";
    };
    aarch64-darwin = {
      url = "https://github.com/storytold/pdfcraft/releases/download/v${version}/pdfcraft-${version}-macos-universal.dmg";
      hash = "sha256-EWc4BFpoRj6xpGXm6u8iZpAqrGmqGhXkocFHLDHYq+k=";
    };
    x86_64-darwin = {
      url = "https://github.com/storytold/pdfcraft/releases/download/v${version}/pdfcraft-${version}-macos-universal.dmg";
      hash = "sha256-EWc4BFpoRj6xpGXm6u8iZpAqrGmqGhXkocFHLDHYq+k=";
    };
  };

  # The macOS CLI ships separately from the DMG.
  darwinCliSrc = fetchurl {
    url = "https://github.com/storytold/pdfcraft/releases/download/v${version}/pdfcraft-cli-${version}-macos-universal.zip";
    hash = "sha256-wguM7WMEF9RwQu43KC/bg2KinrvAsL7D9PY10OKFRfA=";
  };

  src = fetchurl sources.${stdenv.hostPlatform.system};
in

stdenv.mkDerivation (
  {
    pname = "pdfcraft";
    inherit version src;

    # The Linux release binaries are dynamically linked (gnu target), so
    # the interpreter and libgcc need rewriting for the Nix store.
    nativeBuildInputs =
      lib.optionals stdenv.hostPlatform.isLinux [
        autoPatchelfHook
        makeWrapper
      ]
      ++ lib.optionals stdenv.hostPlatform.isDarwin [
        undmg
        unzip
      ];
    buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
      stdenv.cc.cc.lib
      wayland
      libxkbcommon
      vulkan-loader
    ];

    installPhase =
      if stdenv.hostPlatform.isDarwin then
        ''
          runHook preInstall
          mkdir -p $out/Applications $out/bin
          cp -a PdfCraft.app $out/Applications/
          ln -s ../Applications/PdfCraft.app/Contents/MacOS/PdfCraft $out/bin/pdfcraft
          unzip -q ${darwinCliSrc} -d cli
          install -Dm755 cli/*/pdfcraft-cli $out/bin/pdfcraft-cli
          runHook postInstall
        ''
      else
        ''
          install -Dm755 bin/pdfcraft $out/bin/pdfcraft
          install -Dm755 bin/pdfcraft-cli $out/bin/pdfcraft-cli
        '';

    # winit dlopens libwayland-client at runtime (likewise xkbcommon for
    # keyboard input and the Vulkan loader for wgpu rendering), so expose
    # them through the wrapper — autoPatchelfHook only sees linked libs.
    postFixup = lib.optionalString stdenv.hostPlatform.isLinux ''
      wrapProgram $out/bin/pdfcraft \
        --prefix LD_LIBRARY_PATH : "${
          lib.makeLibraryPath [
            wayland
            libxkbcommon
            vulkan-loader
          ]
        }"
      wrapProgram $out/bin/pdfcraft-cli \
        --prefix LD_LIBRARY_PATH : "${
          lib.makeLibraryPath [
            wayland
            libxkbcommon
            vulkan-loader
          ]
        }"
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
  // lib.optionalAttrs stdenv.hostPlatform.isDarwin {
    # undmg leaves the .app at the top of the build directory.
    sourceRoot = ".";
    # Preserve upstream's Developer ID signature; stripping would
    # invalidate it and force an ad-hoc re-sign in fixup.
    dontStrip = true;
  }
)

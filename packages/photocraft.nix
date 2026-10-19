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
  version = "0.10.0";

  # storytold/photocraft — open-source photo editor in pure Rust.
  # Release assets ship a .sha256 sidecar in SHA256SUMS.txt / a GitHub
  # digest next to each asset (`nix hash convert --hash-algo sha256
  # --to sri <hex>`). macOS ships a signed universal DMG plus a separate
  # CLI zip instead of the Linux tarball.
  sources = {
    aarch64-linux = {
      url = "https://github.com/storytold/photocraft/releases/download/v${version}/photocraft-${version}-linux-aarch64.tar.gz";
      hash = "sha256-gpeA0zHmRD3fG62pMu0H4OncVBshOydfPDoyCWB7x8c=";
    };
    x86_64-linux = {
      url = "https://github.com/storytold/photocraft/releases/download/v${version}/photocraft-${version}-linux-x86_64.tar.gz";
      hash = "sha256-xdRVeF2cLq9pW/jmMnxNbSOjnduVamEU8MW2Qyb5hOE=";
    };
    aarch64-darwin = {
      url = "https://github.com/storytold/photocraft/releases/download/v${version}/photocraft-${version}-macos-universal.dmg";
      hash = "sha256-Ly4hoBGejmOysvk9I4gXs3J6+Icgq54rbesUWJJ6Ox8=";
    };
    x86_64-darwin = {
      url = "https://github.com/storytold/photocraft/releases/download/v${version}/photocraft-${version}-macos-universal.dmg";
      hash = "sha256-Ly4hoBGejmOysvk9I4gXs3J6+Icgq54rbesUWJJ6Ox8=";
    };
  };

  # The macOS CLI ships separately from the DMG.
  darwinCliSrc = fetchurl {
    url = "https://github.com/storytold/photocraft/releases/download/v${version}/photocraft-cli-${version}-macos-universal.zip";
    hash = "sha256-V7K/plFL65+FF3+7aDL4qjrr7ghWHXjVSjGCxAQiCSc=";
  };

  src = fetchurl sources.${stdenv.hostPlatform.system};
in

stdenv.mkDerivation (
  {
    pname = "photocraft";
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
          cp -a PhotoCraft.app $out/Applications/
          ln -s ../Applications/PhotoCraft.app/Contents/MacOS/PhotoCraft $out/bin/photocraft
          unzip -q ${darwinCliSrc} -d cli
          install -Dm755 cli/*/photocraft-cli $out/bin/photocraft-cli
          runHook postInstall
        ''
      else
        ''
          install -Dm755 bin/photocraft $out/bin/photocraft
          install -Dm755 bin/photocraft-cli $out/bin/photocraft-cli
        '';

    # winit dlopens libwayland-client at runtime (likewise xkbcommon for
    # keyboard input and the Vulkan loader for wgpu rendering), so expose
    # them through the wrapper — autoPatchelfHook only sees linked libs.
    postFixup = lib.optionalString stdenv.hostPlatform.isLinux ''
      wrapProgram $out/bin/photocraft \
        --prefix LD_LIBRARY_PATH : "${
          lib.makeLibraryPath [
            wayland
            libxkbcommon
            vulkan-loader
          ]
        }"
      wrapProgram $out/bin/photocraft-cli \
        --prefix LD_LIBRARY_PATH : "${
          lib.makeLibraryPath [
            wayland
            libxkbcommon
            vulkan-loader
          ]
        }"
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
  // lib.optionalAttrs stdenv.hostPlatform.isDarwin {
    # undmg leaves the .app at the top of the build directory.
    sourceRoot = ".";
    # Preserve upstream's Developer ID signature; stripping would
    # invalidate it and force an ad-hoc re-sign in fixup.
    dontStrip = true;
  }
)

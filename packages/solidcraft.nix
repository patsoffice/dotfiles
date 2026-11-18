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
  version = "0.44.1";

  # tangency-labs/solidcraft — open-source parametric 3D CAD in pure Rust.
  # Release assets ship checksums in SHA256SUMS.txt (`nix hash convert
  # --hash-algo sha256 --to sri <hex>`). macOS ships a signed universal DMG
  # plus a separate CLI zip instead of the Linux tarball. The Linux
  # tarball wraps its `bin/` tree in a versioned top-level dir, hence the
  # Linux-only sourceRoot below.
  sources = {
    aarch64-linux = {
      url = "https://github.com/tangency-labs/solidcraft/releases/download/v${version}/solidcraft-${version}-linux-aarch64.tar.gz";
      hash = "sha256-Uca4RrjdtUcXJOW0uU/loMtf00pENwaHLBDeJ8N4d0A=";
    };
    x86_64-linux = {
      url = "https://github.com/tangency-labs/solidcraft/releases/download/v${version}/solidcraft-${version}-linux-x86_64.tar.gz";
      hash = "sha256-FkCXdD9v8Rwe65CkMTlkcolV4pdokFIFPk5djSCmQik=";
    };
    aarch64-darwin = {
      url = "https://github.com/tangency-labs/solidcraft/releases/download/v${version}/solidcraft-${version}-macos-universal.dmg";
      hash = "sha256-6JFvxAE1o4tLfBW79GmOKwHC8RQC6dvDLoQCHO5ADUM=";
    };
    x86_64-darwin = {
      url = "https://github.com/tangency-labs/solidcraft/releases/download/v${version}/solidcraft-${version}-macos-universal.dmg";
      hash = "sha256-6JFvxAE1o4tLfBW79GmOKwHC8RQC6dvDLoQCHO5ADUM=";
    };
  };

  # The macOS CLI ships separately from the DMG.
  darwinCliSrc = fetchurl {
    url = "https://github.com/tangency-labs/solidcraft/releases/download/v${version}/solidcraft-cli-${version}-macos-universal.zip";
    hash = "sha256-8yTsSf1Qsw1twYko2EdJuKcqEy5CM9r4ROQis8OLwlE=";
  };

  src = fetchurl sources.${stdenv.hostPlatform.system};
in

stdenv.mkDerivation (
  {
    pname = "solidcraft";
    inherit version src;

    # The Linux tarball wraps the FHS tree in a versioned top-level dir.
    sourceRoot =
      if stdenv.hostPlatform.isLinux then
        "solidcraft-${version}-linux-${stdenv.hostPlatform.linuxArch}"
      else
        "."; # undmg leaves the .app at the top of the build directory.

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

    # Upstream dropped the solvecraft app in 0.44 (apps/ is now solidcraft,
    # solidcraft-cli, solidcraft-web), so only these two binaries ship.
    installPhase =
      if stdenv.hostPlatform.isDarwin then
        ''
          runHook preInstall
          mkdir -p $out/Applications $out/bin
          cp -a SolidCraft.app $out/Applications/
          ln -s ../Applications/SolidCraft.app/Contents/MacOS/SolidCraft $out/bin/solidcraft
          unzip -q ${darwinCliSrc} -d cli
          install -Dm755 cli/*/solidcraft-cli $out/bin/solidcraft-cli
          runHook postInstall
        ''
      else
        ''
          install -Dm755 bin/solidcraft $out/bin/solidcraft
          install -Dm755 bin/solidcraft-cli $out/bin/solidcraft-cli
        '';

    # winit dlopens libwayland-client at runtime (likewise xkbcommon for
    # keyboard input and the Vulkan loader for wgpu rendering), so expose
    # them through the wrapper — autoPatchelfHook only sees linked libs.
    postFixup = lib.optionalString stdenv.hostPlatform.isLinux ''
      wrapProgram $out/bin/solidcraft \
        --prefix LD_LIBRARY_PATH : "${
          lib.makeLibraryPath [
            wayland
            libxkbcommon
            vulkan-loader
          ]
        }"
      wrapProgram $out/bin/solidcraft-cli \
        --prefix LD_LIBRARY_PATH : "${
          lib.makeLibraryPath [
            wayland
            libxkbcommon
            vulkan-loader
          ]
        }"
    '';

    meta = {
      description = "Open-source parametric 3D CAD";
      homepage = "https://github.com/tangency-labs/solidcraft";
      license = with lib.licenses; [
        mit
        asl20
      ];
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
      mainProgram = "solidcraft";
      platforms = builtins.attrNames sources;
    };
  }
  // lib.optionalAttrs stdenv.hostPlatform.isDarwin {
    # Preserve upstream's Developer ID signature; stripping would
    # invalidate it and force an ad-hoc re-sign in fixup.
    dontStrip = true;
  }
)

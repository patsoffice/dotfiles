{
  lib,
  buildFHSEnv,
  dash,
  fetchzip,
  runCommand,
  writeShellScript,
  # VPinballX runtime deps (from vpinball-nix/release.nix)
  libGL,
  libGLU,
  libglvnd,
  libdrm,
  mesa,
  vulkan-loader,
  wayland,
  egl-wayland,
  libxkbcommon,
  alsa-lib,
  pipewire,
  libpulseaudio,
  hidapi,
  libftdi1,
  libusb1,
  systemd,
  dbus,
  # Chromium / GTK / fonts (VPinFE extras)
  nss,
  nspr,
  gtk3,
  cairo,
  pango,
  gdk-pixbuf,
  at-spi2-atk,
  at-spi2-core,
  cups,
  expat,
  fontconfig,
  freetype,
  libx11,
  libxcb,
  libxrandr,
  libxcursor,
  libxfixes,
  libxext,
  libxi,
  libxscrnsaver,
  libxtst,
  libxrender,
  libxcomposite,
  libxdamage,
}:

let
  version = "1.1.56";

  rawSrc = fetchzip {
    url = "https://github.com/superhac/vpinfe/releases/download/v${version}/vpinfe-v${version}-linux-x64.zip";
    hash = "sha256-lIzDDWxMc6hc8Kp/SR4f9JLgED/X9DPl/MtJrttmB1M=";
    stripRoot = false;
  };

  # The zip ships binaries without execute bits; fix that and also replace
  # the bundled chrome binary with a wrapper that forces XWayland. VPinFE
  # passes --ozone-platform=wayland to chromium, and three chromium-wayland
  # windows being created in parallel trigger a race in Sway's xdg_surface
  # handling (0x0 configure event → FATAL in xdg_surface.cc:64). Running
  # chromium under X11 via XWayland sidesteps the xdg_shell code path.
  src = runCommand "vpinfe-${version}-src" { } ''
    cp -r ${rawSrc} $out
    chmod -R u+w $out
    chmod +x $out/vpinfe/vpinfe
    find $out/vpinfe/_internal/chromium -type f -exec chmod +x {} +

    chrome=$out/vpinfe/_internal/chromium/linux/chrome/chrome
    mv "$chrome" "$chrome.real"
    # dash (not bash) because VPinFE spawns chrome with LD_LIBRARY_PATH
    # pointing at its bundled _internal/ dir, which contains a libreadline
    # bash can't use (undefined rl_completion_rewrite_hook). dash doesn't
    # link readline.
    cat > "$chrome" <<EOF
    #!${dash}/bin/dash
    args=""
    for arg in "\$@"; do
      case "\$arg" in
        --ozone-platform=*) ;;
        *) args="\$args \"\$arg\"" ;;
      esac
    done
    eval set -- \$args
    exec "\$0.real" --ozone-platform=x11 "\$@"
    EOF
    chmod +x "$chrome"
  '';

  launcher = writeShellScript "vpinfe-launcher" ''
    exec ${src}/vpinfe/vpinfe "$@"
  '';
in

buildFHSEnv {
  pname = "vpinfe";
  inherit version;

  targetPkgs =
    pkgs: with pkgs; [
      # VPinballX runtime
      libGL
      libGLU
      libglvnd
      libdrm
      mesa
      vulkan-loader
      wayland
      egl-wayland
      libx11
      libxcb
      libxrandr
      libxcursor
      libxfixes
      libxext
      libxi
      libxscrnsaver
      libxtst
      libxrender
      libxcomposite
      libxdamage
      libxkbcommon
      alsa-lib
      pipewire
      libpulseaudio
      hidapi
      libftdi1
      libusb1
      systemd
      dbus
      zlib
      stdenv.cc.cc.lib

      # Chromium / GTK / fonts for VPinFE
      nss
      nspr
      gtk3
      cairo
      pango
      gdk-pixbuf
      at-spi2-atk
      at-spi2-core
      cups
      expat
      fontconfig
      freetype
    ];

  runScript = "${launcher}";

  meta = {
    description = "Frontend/launcher for Visual Pinball X cabinets";
    homepage = "https://github.com/superhac/vpinfe";
    license = lib.licenses.mit;
    mainProgram = "vpinfe";
    platforms = [ "x86_64-linux" ];
  };
}

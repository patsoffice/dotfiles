{
  lib,
  buildFHSEnv,
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

  # Use the "slim" linux release — no bundled chromium. The system
  # google-chrome (added to the FHS env below) ships H.264/AAC so the
  # Revolution theme's splash video can actually play on the table
  # window. The fat bundle's chromium strips those codecs, which stalls
  # the splash JS on the table window forever.
  rawSrc = fetchzip {
    url = "https://github.com/superhac/vpinfe/releases/download/v${version}/vpinfe-v${version}-linux-x64-slim.zip";
    hash = "sha256-OGXbsrQcJo/efsCa/4m7HrCjxM9yzG2y29T+9EyC1Do=";
    stripRoot = false;
  };

  # The zip ships the vpinfe binary without an execute bit; fix that.
  src = runCommand "vpinfe-${version}-src" { } ''
    cp -r ${rawSrc} $out
    chmod -R u+w $out
    chmod +x $out/vpinfe/vpinfe
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

      # A shell whose startup doesn't touch libreadline (bash's /bin/sh
      # gets confused by VPinFE's LD_LIBRARY_PATH). Used by the
      # VPinballX launch wrapper.
      dash

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

      # System browser with proprietary codecs (H.264 / AAC) for the
      # Revolution theme's splash videos.
      google-chrome
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

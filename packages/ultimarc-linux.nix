{
  lib,
  stdenv,
  fetchFromGitHub,
  autoreconfHook,
  pkg-config,
  libusb1,
  json_c,
  udev,
}:

# katie-snow/Ultimarc-linux — the `umtool` CLI for programming Ultimarc
# arcade control boards (IPAC, U-HID, PacDrive, UltraStik, …) from JSON
# config files. Autotools project; built statically (--disable-shared) so
# umtool is a self-contained binary that links libultimarc internally.
#
# The upstream 21-ultimarc.rules udev file is intentionally NOT installed —
# the arcade host already grants Ultimarc devices (vendor d209) input-group
# access via services.udev.extraRules.
stdenv.mkDerivation (finalAttrs: {
  pname = "ultimarc-linux";
  version = "1.2.0";

  src = fetchFromGitHub {
    owner = "katie-snow";
    repo = "Ultimarc-linux";
    rev = finalAttrs.version;
    hash = "sha256-aDZ1YyNyCSQiTG4mKJZ7AHaJIXa3v0N5ksTFy3mflIA=";
  };

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
  ];

  buildInputs = [
    libusb1
    json_c
    udev
  ];

  configureFlags = [ "--disable-shared" ];

  meta = {
    description = "umtool CLI for configuring Ultimarc arcade control boards";
    homepage = "https://github.com/katie-snow/Ultimarc-linux";
    license = lib.licenses.gpl2Only;
    mainProgram = "umtool";
    platforms = lib.platforms.linux;
  };
})

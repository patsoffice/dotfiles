# Lens Desktop (Kubernetes IDE), tracking the latest upstream AppImage rather
# than the older pin in nixpkgs. Mirrors nixpkgs' pkgs/by-name/le/lens/linux.nix
# (AppImage extraction, FHS/Electron-Wayland wrapping, desktop/icon install) but
# with a self-managed version + hash.
#
# To bump: curl https://api.k8slens.dev/binaries/latest-linux.yml
#   - version = the feed's `version` minus the "-latest" suffix
#   - hash    = "sha512-" + the feed's top-level `sha512`
{
  appimageTools,
  fetchurl,
  makeWrapper,
  lib,
}:
let
  pname = "lens-desktop";
  version = "2026.5.181248";
  src = fetchurl {
    url = "https://api.k8slens.dev/binaries/Lens-${version}-latest.x86_64.AppImage";
    hash = "sha512-2GpYLrK42wibmlc+UTs748KPAei135zTA3wtp2uPZrjqAZF4gXkhCC99jIuqkjnMJ7WU4G1em8hQbecupn2kUQ==";
  };
  appimageContents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  nativeBuildInputs = [ makeWrapper ];

  extraInstallCommands = ''
    wrapProgram $out/bin/${pname} \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}"
    install -m 444 -D ${appimageContents}/${pname}.desktop $out/share/applications/${pname}.desktop
    install -m 444 -D ${appimageContents}/usr/share/icons/hicolor/512x512/apps/${pname}.png \
       $out/share/icons/hicolor/512x512/apps/${pname}.png
    substituteInPlace $out/share/applications/${pname}.desktop \
      --replace 'Exec=AppRun' 'Exec=${pname}'
  '';

  extraPkgs = pkgs: [ pkgs.nss_latest ];

  meta = {
    description = "Kubernetes IDE (latest upstream AppImage)";
    homepage = "https://k8slens.dev/";
    license = lib.licenses.lens;
    mainProgram = pname;
    platforms = [ "x86_64-linux" ];
  };
}

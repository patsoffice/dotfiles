{
  lib,
  buildPythonApplication,
  fetchFromGitHub,
  setuptools,
  babel,
  fastjsonschema,
  pyside6,
  python-easy-json,
  python-libusb,
  qt6,
}:

# katie-snow/QtPyUltimarc — Python + QML successor to Ultimarc-linux. Ships
# two entry points: `ultimarc` (CLI) and `ultimarc-ui` (PySide6/QML GUI).
# The GUI loads its QML from a compiled Qt resource module
# (ultimarc/qml/rc_assets.py), so no external QML path is needed — but the
# PySide6 process still needs Qt's plugin/QML import paths, hence the Qt
# wrapping below.
buildPythonApplication rec {
  pname = "qtpyultimarc";
  version = "1.0.0-alpha.9";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "katie-snow";
    repo = "QtPyUltimarc";
    rev = version;
    hash = "sha256-c2Dd6bR6aKCMdHBLV3t/ty3AdkLAgiDf+7B9WJ1AgVI=";
  };

  build-system = [ setuptools ];

  nativeBuildInputs = [ qt6.wrapQtAppsHook ];

  # Pulled in so wrapQtAppsHook adds their QML import + plugin paths to the
  # wrapper. In Qt6, Quick Controls (incl. the Fusion style) ship inside
  # qtdeclarative; qtsvg supplies the icon image format used by the editor.
  buildInputs = [
    qt6.qtdeclarative
    qt6.qtsvg
  ];

  dependencies = [
    babel
    fastjsonschema
    pyside6
    python-easy-json
    python-libusb
  ];

  # buildPythonApplication wraps the console scripts itself; let it fold in the
  # Qt env (qtWrapperArgs) rather than double-wrapping via wrapQtAppsHook.
  dontWrapQtApps = true;
  preFixup = ''
    makeWrapperArgs+=("''${qtWrapperArgs[@]}")
  '';

  # Tests need real Ultimarc hardware; just check the package imports.
  doCheck = false;
  pythonImportsCheck = [ "ultimarc" ];

  meta = {
    description = "Python/QML tool for configuring Ultimarc USB devices";
    homepage = "https://github.com/katie-snow/QtPyUltimarc";
    license = lib.licenses.gpl3Only;
    mainProgram = "ultimarc-ui";
    platforms = lib.platforms.linux;
  };
}

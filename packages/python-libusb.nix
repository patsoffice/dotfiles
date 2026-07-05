{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  pkg-about,
  # The C library (nixpkgs top-level libusb1), NOT python3Packages.libusb1
  # (python-libusb1). Passed explicitly from the overlay.
  libusb1,
}:

# libusb — Adam Karpierz' pure-ctypes wrapper around libusb-1.0 (import name
# `libusb`, distinct from python3Packages.libusb1 whose import name is `usb1`).
# Runtime dependency of QtPyUltimarc (`import libusb as usb`); not in nixpkgs.
#
# Pinned to 1.0.28: it depends only on pkg-about (packaged). 1.0.29 adds
# py-utlx, which nixpkgs does not have.
buildPythonPackage rec {
  pname = "libusb";
  version = "1.0.28";
  pyproject = true;

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-8Ylppy6caIFiV7uhPvWD8kX+s9WS+8QuxYeWAegGUWc=";
  };

  build-system = [ setuptools ];

  dependencies = [ pkg-about ];

  # build-system.requires lists tox (for the author's test matrix); it isn't
  # needed to build the wheel and pulls in a heavy tree, so drop it.
  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail "'setuptools>=80.1.0', 'packaging>=25.0.0', 'tox>=4.25.0'" \
                     "'setuptools>=80.1.0'"

    # The wheel vendors a prebuilt manylinux libusb-1.0.so per arch; it won't
    # run on NixOS. The ctypes loader (_platform/_linux/__init__.py) has no
    # config override set, so it falls back to this bundled path — swap in the
    # nixpkgs build so the store-correct library is loaded.
    cp --remove-destination ${lib.getLib libusb1}/lib/libusb-1.0.so \
      src/libusb/_platform/_linux/x64/libusb-1.0.so
  '';

  # Importing dlopens the (now nixpkgs) libusb-1.0.so, so this also proves the
  # patch worked.
  pythonImportsCheck = [ "libusb" ];

  meta = {
    description = "Pure-Python ctypes bindings for libusb-1.0";
    homepage = "https://github.com/karpierz/libusb";
    license = lib.licenses.zlib;
    platforms = lib.platforms.linux;
  };
}

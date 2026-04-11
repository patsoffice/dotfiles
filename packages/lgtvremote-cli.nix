{
  lib,
  python3Packages,
  fetchFromGitHub,
}:

python3Packages.buildPythonApplication rec {
  pname = "lgtvremote-cli";
  version = "1.3.4";

  src = fetchFromGitHub {
    owner = "griches";
    repo = "lgtvremote-cli";
    tag = "v${version}";
    hash = "sha256-2+ux1O49XwQxEsveu4sKjo6QhGjalPDfXauT+p7/IrM=";
  };

  format = "pyproject";

  nativeBuildInputs = [ python3Packages.setuptools ];

  meta = {
    description = "Command line interface for controlling LG webOS TVs";
    homepage = "https://github.com/griches/lgtvremote-cli";
    license = lib.licenses.mit;
    mainProgram = "lgtv";
  };
}

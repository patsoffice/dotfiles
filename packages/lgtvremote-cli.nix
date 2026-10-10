{
  lib,
  python3Packages,
  fetchFromGitHub,
}:

python3Packages.buildPythonApplication rec {
  pname = "lgtvremote-cli";
  version = "1.6.4";

  src = fetchFromGitHub {
    owner = "griches";
    repo = "lgtvremote-cli";
    tag = "v${version}";
    hash = "sha256-V0WVtxX6GUroKS3PsT2UawOZQYNxbCf+GaMjToAoOHg=";
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

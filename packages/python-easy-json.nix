{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  dateutils,
}:

# python-easy-json — JSON <-> typed object mapper. Runtime dependency of
# QtPyUltimarc; not in nixpkgs.
buildPythonPackage rec {
  pname = "python-easy-json";
  version = "1.2.5";
  pyproject = true;

  src = fetchPypi {
    pname = "python_easy_json";
    inherit version;
    hash = "sha256-BJ+5vqHZTx9dD6NkGOb+AcUQoOjdw5hq0DbRLLc7bFY=";
  };

  build-system = [ setuptools ];

  dependencies = [ dateutils ];

  pythonImportsCheck = [ "python_easy_json" ];

  meta = {
    description = "Load JSON data into typed Python objects";
    homepage = "https://github.com/apolloswtf/python_easy_json";
    license = lib.licenses.mit;
  };
}

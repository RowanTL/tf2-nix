# casual-pre-loader's VPK and PCF library, which isn't in nixpkgs.
{ buildPythonPackage, fetchPypi }:

buildPythonPackage rec {
  pname = "valve_parsers";
  version = "1.2.2";
  format = "wheel";
  src = fetchPypi {
    inherit pname version format;
    dist = "py3";
    python = "py3";
    hash = "sha256-omWEitZaAEc26PQzP5ZwiA8PBz/pmxsgvva4rFsdz3A=";
  };
  pythonImportsCheck = [ "valve_parsers" ];
}

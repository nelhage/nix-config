{ stdenv, ... }:
stdenv.mkDerivation {
  pname = "nelhage-scripts";
  version = "0.1.0";
  src = ./bin;
  installPhase = ''
    install -d $out/bin
    install ./* $out/bin/
  '';
}

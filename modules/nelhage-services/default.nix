{ stdenv,
  writeTextFile,
  bash,
  docker-compose,
  ...
}:
let
  binScript = ''
#!${bash}/bin/bash
exec ${docker-compose}/bin/docker-compose \
  -f ${config.outPath}/docker-compose.yaml \
  -f $HOME/nelhage.com/secrets/docker-compose.credentials.yaml \
  "$@"
'';
  binFile = writeTextFile {
    name = "nelhage.com-docker-compose";
    text = binScript;
    executable = true;
    destination = "/bin/nelhage.com-docker-compose";
  };
  config = stdenv.mkDerivation {
    name = "nelhage.com-service-config-0.1";
    src = ./config;
    buildInputs = [ ];
    dontPatchShebangs = true;
    installPhase = ''
      cp -a ./ $out/
    '';
  };
  bin = stdenv.mkDerivation {
    name = "nelhage.com-service-bin-0.1";
    src = ./config;
    buildInputs = [ ];
    buildPhase = ''
      mkdir -p bin/
      ln -nsf ${binFile}/bin/* bin/
    '';

    installPhase = ''
      cp -a ./ $out/
    '';
  };
in
bin

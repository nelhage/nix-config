{
  stdenv,
  writeTextFile,
  bash,
  docker,
  credentials ? "$HOME/nelhage.com/secrets/docker-compose.credentials.yaml",
  ...
}:
let
  binScript = ''
    #!${bash}/bin/bash
    # Go through the wrapped `docker` CLI (rather than the standalone
    # docker-compose binary) so that the buildx + compose plugins are
    # discoverable. nixpkgs only advertises those plugins via DOCKER_CLI_PLUGIN_DIRS
    # for pkgs.docker; the bare docker-compose binary can't find buildx and
    # `build` silently falls back to the legacy builder (breaking --mount, etc.).
    set -eu
    extra_args=()
    override_env="$HOME/Sync/config/nelhage-services.env"
    if [ -f "$override_env" ]; then
       extra_args+=(--env-file "$override_env")
    fi
    exec ${docker}/bin/docker compose \
      -f ${config.outPath}/docker-compose.yaml \
      -f ${credentials} \
      --env-file ${config.outPath}/.env \
      "''${extra_args[@]}" \
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
    src = binFile;
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
bin // { binary = "${bin}/bin/${binFile.name}"; }

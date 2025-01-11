{
  # Package information
  name,
  version,
  src,
  buildInputs ? [ ],
  propagatedBuildInputs ? [ ],

  # Dependencies
  system,
  uv,
  lib,
  python3,
  stdenv,

  # Pinning packages
  packagesHash ? { },
  packagesHashAlgo ? "sha256",
}:
let
  fs = lib.fileset;
  path = lib.path;
  uvFiles = (
    fs.unions [
      (path.append src "./pyproject.toml")
      (path.append src "./uv.lock")
    ]
  );
  uvEnv = {
    UV_PYTHON = "${python3}/bin/python";
    UV_PYTHON_DOWNLOADS = "never";
    UV_NO_PROGRESS = "1";
    UV_LOCKED = "1";
    UV_NO_CACHE = "1";
    UV_OFFLINE = "1";
  };
  requirements = stdenv.mkDerivation {
    pname = "${name}-requirements";
    version = version;
    src = fs.toSource {
      root = src;
      fileset = uvFiles;
    };
    buildPhase = ''
      mkdir -p $out
      uv export > $out/requirements.txt
    '';
    env = uvEnv;

    dontFixup = true;

    buildInputs = [ uv ];
  };
  pkgs = stdenv.mkDerivation {
    pname = "${name}-pkgs";
    version = version;
    src = fs.toSource {
      root = src;
      fileset = uvFiles;
    };
    buildPhase = ''
      mkdir -p $out
      pip --no-cache-dir download \
       --progress-bar off \
       -d $out \
       -r ${requirements}/requirements.txt
    '';

    buildInputs = [ python3.pkgs.pip ];
    dontFixup = true;

    outputHash = if builtins.isAttrs packagesHash then (packagesHash.${system} or "") else packagesHash;
    outputHashAlgo = packagesHashAlgo;
    outputHashMode = "recursive";
  };
  venv = stdenv.mkDerivation {
    pname = "${name}";
    version = version;
    src = src;
    buildPhase = ''
      uv venv --no-project $out
      env UV_PYTHON=$out/bin/python3 VIRTUAL_ENV=$out \
      uv --offline pip install \
       --no-index \
       --find-links ${pkgs}/ \
       -r ${requirements}/requirements.txt
    '';

    env = uvEnv;
    dontStrip = true;

    buildInputs = [
      uv
    ] ++ buildInputs;
    inherit propagatedBuildInputs;

    passthru = {
      inherit requirements pkgs;
    };
  };
in
venv

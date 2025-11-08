{
  # Package information
  name,
  version,
  src,
  buildInputs ? [ ],
  nativeBuildInputs ? [ ],
  propagatedBuildInputs ? [ ],

  # Dependencies
  system,
  uv,
  lib,
  python3,
  stdenv,
  autoPatchelfHook,

  # Pinning packages
  packagesHash ? { },
  packagesHashAlgo ? "sha256",
  findLinks ? [ ],
  useUvPip ? false,
}:
let
  fs = lib.fileset;
  path = lib.path;
  strings = lib.strings;
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
    UV_FROZEN = "1";
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
    buildPhase =
      let
        findLinksArgs = strings.concatMapStrings (x: "--find-links ${x} ") findLinks;
      in
      ''
        mkdir -p $out
        pip --no-cache-dir download \
         --progress-bar off \
         ${findLinksArgs} \
         -d $out \
         -r ${requirements}/requirements.txt
      '';

    buildInputs = [ python3.pkgs.pip ];
    dontFixup = true;

    outputHash = if builtins.isAttrs packagesHash then (packagesHash.${system} or "") else packagesHash;
    outputHashAlgo = packagesHashAlgo;
    outputHashMode = "recursive";
  };
  venv =
    let
      venv = if useUvPip then "uv venv --no-project" else "python3 -m venv $out";
      pipInstall =
        if useUvPip then
          "env UV_PYTHON=$out/bin/python3 uv --offline pip install"
        else
          "$out/bin/pip install";
    in
    stdenv.mkDerivation {
      pname = "${name}";
      version = version;
      src = src;
      buildPhase = ''
        ${venv} $out
        sed -re 's|( @ )(https?://.*/)([^/]+) |\1 file://${pkgs}/\3 |' \
            ${requirements}/requirements.txt > /tmp/requirements.txt
        VIRTUAL_ENV=$out ${pipInstall} \
         --no-index \
         --find-links ${pkgs}/ \
         -r /tmp/requirements.txt
      '';

      env = uvEnv;
      dontStrip = true;

      buildInputs =
        [
          python3
        ]
        ++ (if useUvPip then [ uv ] else [ ])
        ++ buildInputs;
      inherit propagatedBuildInputs;

      nativeBuildInputs =
        nativeBuildInputs
        ++ (
          if stdenv.isDarwin then
            [ ]
          else
            [
              autoPatchelfHook
            ]
        );

      passthru = {
        inherit requirements pkgs;
      };
    };
in
venv

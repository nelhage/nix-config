{
  callPackage,
  python3,
  lib,
  ...
}:
callPackage ../../lib/build-uv-package.nix {
  name = "jupyterlab-env";
  version = "0.1.0";
  src = ./.;

  packagesHash = lib.trivial.importJSON ./hashes.json;
  useUvPip = true;

  inherit python3;
}

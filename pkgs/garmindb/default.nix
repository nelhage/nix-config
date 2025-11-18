{
  callPackage,
  python3,
  lib,
  libz,
  ...
}:
callPackage ../../lib/build-uv-package.nix {
  name = "garmin";
  version = "0.1.0";
  src = ./.;

  packagesHash = lib.trivial.importJSON ./hashes.json;
  useUvPip = true;

  buildInputs = [
    libz
  ];

  inherit python3;
}

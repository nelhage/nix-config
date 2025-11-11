{
  mkShell,
  stdenv,
  python313,
  uv,
  lib,
}:
mkShell {
  packages = [
    python313
    uv
  ];
  LD_LIBRARY_PATH = lib.makeLibraryPath [ stdenv.cc.cc.lib ];
}

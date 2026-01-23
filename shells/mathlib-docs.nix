{
  mkShell,
  stdenv,
  python313,
  lib,
  pkgs,
}:
mkShell {
  packages = [
    python313
    pkgs.uv
    pkgs.bubblewrap
    pkgs.socat
  ];
  LD_LIBRARY_PATH = lib.makeLibraryPath [ stdenv.cc.cc.lib ];
}

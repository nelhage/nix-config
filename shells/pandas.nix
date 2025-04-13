{
  mkShell,
  python313,
  uv,
  ninja,
  stdenv,
  lib,
  pkgs,
}:
mkShell rec {
  buildInputs = [
    (python313.withPackages (p: [
      p.cmake
      p.cython
    ]))
    pkgs.zlib
    pkgs.glib
    uv
    ninja
  ];
  shellHook = ''
    export LD_LIBRARY_PATH="${lib.makeLibraryPath buildInputs}:$LD_LIBRARY_PATH"
    export LD_LIBRARY_PATH="${stdenv.cc.cc.lib}/lib/:$LD_LIBRARY_PATH"
  '';
}

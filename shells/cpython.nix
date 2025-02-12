{
  mkShell,
  python3,
  llvmPackages_19,
}:
let
  pkgs = python3.buildInputs ++ python3.nativeBuildInputs;
in
mkShell {
  packages = pkgs;
  passthru = {
    clang = mkShell.override ({ stdenv = llvmPackages_19.stdenv; }) {
      packages = pkgs ++ [ llvmPackages_19.bintools-unwrapped ];
    };
  };
}

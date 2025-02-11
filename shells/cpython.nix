{
  mkShell,
  python3,
  llvmPackages_19,
}:
mkShell.override ({ stdenv = llvmPackages_19.stdenv; }) {
  packages =
    [ llvmPackages_19.bintools-unwrapped ] ++ python3.buildInputs ++ python3.nativeBuildInputs;
}

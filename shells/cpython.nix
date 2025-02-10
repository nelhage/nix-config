{
  mkShell,
  python3,
  llvmPackages_19,
}:
mkShell.override ({ stdenv = llvmPackages_19.stdenv; }) {
  packages = [ ] ++ python3.buildInputs ++ python3.nativeBuildInputs;
}

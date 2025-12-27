{
  pkgs,
  llvmPackages_20,
  mkShell,
}:
mkShell {
  stdenv = llvmPackages_20.stdenv;
  packages = [
    pkgs.meson
    pkgs.ninja
    pkgs.bear
  ];
}

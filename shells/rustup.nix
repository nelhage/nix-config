{
  pkgs,
  mkShell,
}:
mkShell {
  packages = [
    pkgs.rustup
  ];
}

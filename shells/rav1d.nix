{
  pkgs,
  mkShell,
}:
mkShell {
  packages = [
    pkgs.rustup
    pkgs.nasm
  ];
}

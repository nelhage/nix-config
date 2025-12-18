{
  pkgs,
  mkShell,
}:
mkShell {
  packages = [
    pkgs.cargo
    pkgs.rustc
    pkgs.rust-analyzer
    pkgs.rustfmt
    pkgs.clippy
    pkgs.bubblewrap
    pkgs.socat
  ];

  RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
}

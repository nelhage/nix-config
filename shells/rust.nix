{
  cargo,
  rust,
  rustc,
  rust-analyzer,
  rustfmt,
  clippy,
  mkShell,
}:
mkShell {
  packages = [
    cargo
    rustc
    rust-analyzer
    rustfmt
    clippy
  ];

  RUST_SRC_PATH = "${rust.packages.stable.rustPlatform.rustLibSrc}";
}

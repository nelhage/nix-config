{
  pkgs,
  mkShell,
}:
mkShell {
  packages =
    [
      pkgs.cargo
      pkgs.rustc
      pkgs.rust-analyzer
      pkgs.rustfmt
      pkgs.clippy
      pkgs.socat
    ]
    ++ (
      if pkgs.hostPlatform.isLinux then
        [
          pkgs.bubblewrap
        ]
      else
        [ ]
    );

  RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";
}

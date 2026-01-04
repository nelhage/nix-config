{
  pkgs,
  mkShell,
}:
mkShell {
  packages =
    [
      pkgs.rustup
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

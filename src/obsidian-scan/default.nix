{ nixpkgs, ... }:
let
  forAllSystems = nixpkgs.lib.genAttrs [
    "aarch64-linux"
    "x86_64-linux"
    "aarch64-darwin"
  ];
in
rec {
  devShells = forAllSystems (
    system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      obsidian-scan = pkgs.mkShell {
        packages = [
          pkgs.cargo
          pkgs.rustc
          pkgs.rust-analyzer
          pkgs.rustfmt
          pkgs.clippy
        ];

        RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";

        shellHook = ''
          # Git on macos misbehaves when this is set.
          unset DEVELOPER_DIR
        '';
      };
    }
  );

  packages = forAllSystems (
    system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      obsidian-scan = pkgs.rustPlatform.buildRustPackage rec {
        pname = "obsidian-scan";
        version = "0.0.1";
        src = ./.;

        cargoHash = "sha256-hJcpt3AuVvs0qkeZ7PiZ750zhmBokbWEe5XTAh3iEcU";
      };
    }
  );

  overlays = {
    obsidian-scan = final: prev: {
      obsidian-scan = packages.${prev.system}.obsidian-scan;
    };
  };
}

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
          pkgs.bashInteractive
          pkgs.cargo
          pkgs.rustfmt
        ];
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

        cargoHash = "sha256-dy6jX5FaH8zoLbQMr3bT2P9OaGSUGw3gosQobpjoOdg";
      };
    }
  );

  overlays = {
    obsidian-scan = final: prev: {
      obsidian-scan = packages.${prev.system}.obsidian-scan;
    };
  };
}

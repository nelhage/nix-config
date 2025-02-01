{ nixpkgs, self, ... }:
let
  forAllSystems = nixpkgs.lib.genAttrs [
    "aarch64-linux"
    "x86_64-linux"
    "aarch64-darwin"
  ];
in
{
  devShells = forAllSystems (system: {
    obsidian-scan = self.devShells.${system}.rust;
  });

  packages = forAllSystems (
    system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      fs = pkgs.lib.fileset;
    in
    {
      obsidian-scan = pkgs.rustPlatform.buildRustPackage {
        pname = "obsidian-scan";
        version = "0.1.0";
        src = fs.toSource {
          root = ./.;
          fileset = (
            fs.unions [
              ./Cargo.lock
              ./Cargo.toml
              ./src
            ]
          );
        };

        cargoHash = "sha256-MaUsOKp+xpYMA3nLsLpN7LyLX5+qrF+PQ8DlnN6Zrvo=";

        passthru = {
          elisp = pkgs.stdenv.mkDerivation {
            pname = "obsidian-scan";
            version = "0.1.0";
            src = ./emacs;
            installPhase = ''
              install -d $out
              install *.el $out/
            '';
          };

        };
      };
    }
  );

  overlays = {
    obsidian-scan = final: prev: {
      obsidian-scan = self.packages.${prev.system}.obsidian-scan;
    };
  };
}

{ nixpkgs, ... }:
let
  forAllSystems = nixpkgs.lib.genAttrs [
    "aarch64-linux"
    "x86_64-linux"
    "aarch64-darwin"
  ];
in
{
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
        ];
      };
    }
  );
}

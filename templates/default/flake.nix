{
  description = "direnv development template";
  inputs.nelhage.url = "github:nelhage/nix-config";
  inputs.nixpkgs.follows = "nelhage/nixpkgs";

  outputs =
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
          default = pkgs.mkShell {
            packages = [
            ];
          };
        }
      );
    };
}

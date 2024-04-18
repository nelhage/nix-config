{ nixpkgs, ... }:
{
  home.homeDirectory = "/Users/nelhage";

  nix.registry = {
    nixpkgs = {
      from = {
        type = "indirect";
        id = "nixpkgs";
      };
      to = {
        type = "path";
        path = nixpkgs.outPath;
      };
    };
  };
}

{ nixpkgs, ... }:
{
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

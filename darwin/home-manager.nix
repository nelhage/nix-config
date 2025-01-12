{ ... }:
{
  home-manager = {
    users.nelhage =
      { ... }:
      {
        imports = [
          ../home-manager/home.nix
          ../home-manager/laptop.nix
          ../home-manager/darwin.nix
        ];
      };
    useGlobalPkgs = true;
    useUserPackages = true;
  };
}

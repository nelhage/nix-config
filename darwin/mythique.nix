{
  pkgs,
  ...
}:
{
  imports = [
    ./common.nix
    ./home-manager.nix
  ];

  home-manager.users.nelhage =
    { ... }:
    {
      sync.autocommit.enable = true;
    };
}

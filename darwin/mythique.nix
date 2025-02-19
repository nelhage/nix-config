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
      imports = [
        ../home-manager/litestream.nix
      ];

      xdg.configFile."litestream-garmin.yml".source = ./litestream-garmin.yml;

      sync.autocommit.enable = true;
    };
}

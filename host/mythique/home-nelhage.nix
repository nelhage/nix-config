{ ... }:
{
  imports = [
    ../../home-manager/local-caddy.nix
  ];

  nelhage.sync.autocommit.enable = false;
}

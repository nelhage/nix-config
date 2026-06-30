{ lib, ... }:
{
  imports = [
    ../../darwin/common.nix
    ../../darwin/home-manager.nix
  ];

  home-manager.users.nelhage = import ./home-nelhage.nix;

  networking.hostName = "quintique";
  nix.enable = false;
  nix.optimise.automatic = lib.mkForce false;
}

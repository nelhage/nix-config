{ lib, pkgs, ... }:
{
  imports = [
    ./common.nix
  ];

  boot.blacklistedKernelModules = [ "algif_aead" ];
}

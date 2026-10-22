{ lib, pkgs, ... }:
{
  imports = [
    ./common.nix
    ./emudhra.nix
  ];

  boot.blacklistedKernelModules = [ "algif_aead" ];
}

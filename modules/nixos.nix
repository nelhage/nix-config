{ lib, pkgs, ... }:
{
  imports = [
    ./common.nix
    ./block-sctp.nix
  ];

  boot.blacklistedKernelModules = [ "algif_aead" ];
}

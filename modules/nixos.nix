{ lib, pkgs, ... }:
{
  imports = [
    ./common.nix
    ./emudhra.nix
    ./brotli.nix
  ];

  boot.blacklistedKernelModules = [ "algif_aead" ];
}

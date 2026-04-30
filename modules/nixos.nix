{ ... }:
{
  imports = [ ./common.nix ];

  boot.blacklistedKernelModules = [ "algif_aead" ];
}

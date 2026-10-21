{ lib, pkgs, ... }:
{
  imports = [ ./common.nix ];

  boot.blacklistedKernelModules = [ "algif_aead" ];

  # Distrust the compromised eMudhra emSign roots, mirroring nixpkgs' own
  # stopgap in nixos/modules/security/ca.nix, until NSS 3.131.1 (which drops
  # them) reaches nixos-unstable. Throws once it does, so this can't silently
  # outlive its usefulness.
  security.pki.caCertificateBlacklist =
    if lib.versionAtLeast pkgs.cacert.version "3.131.1" then
      throw ''
        nixpkgs' `cacert` is now version ${pkgs.cacert.version}, which drops the
        compromised eMudhra roots: remove `security.pki.caCertificateBlacklist`
        from modules/nixos.nix.
      ''
    else
      [
        "emSign ECC Root CA - G3"
        "emSign Root CA - C1"
        "emSign ECC Root CA - C3"
      ];
}

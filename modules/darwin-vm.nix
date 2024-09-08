{pkgs, nixpkgs, ...}: {
  virtualisation.vmVariant.virtualisation = {
    graphics = false;
    host.pkgs = nixpkgs.legacyPackages.aarch64-darwin;
  };
}

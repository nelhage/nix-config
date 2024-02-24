{ modulesPath, config, lib, pkgs, ... }: {
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix") ./disk-config.nix ];
  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a
    # EF02 partition to the list already
    #
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  users.users.root.home = lib.mkForce "/data/home/root";
  users.users.nelhage.home = "/data/home/nelhage";

  networking = {
    hostName = "hw4";
    domain = "nelhage.com";
  };

  system.stateVersion = "23.11";
}

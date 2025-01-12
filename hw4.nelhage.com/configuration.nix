{
  modulesPath,
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./disk-config.nix
  ];
  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a
    # EF02 partition to the list already
    #
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  networking = {
    hostName = "hw4";
    domain = "nelhage.com";
  };

  boot.swraid.mdadmConf = ''
    MAILADDR nelhage@nelhage.com
    MAILFROM hw4.nelhage.com
  '';

  services.syncthing.guiAddress = "100.78.93.125:8384";

  system.stateVersion = "23.11";

  home-manager.users.nelhage = { ... }: { };

  garmindb.enable = true;
}

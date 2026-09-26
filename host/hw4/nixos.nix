{
  modulesPath,
  config,
  lib,
  pkgs,
  constants,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ../../modules/nelhage.com.nix
    ../../modules/nixos.nix
    ../../modules/calibre-server.nix
    ../../modules/lab.nelhage.com.nix
    ./hardware-configuration.nix
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

  nelhage.tailscaleAddress = constants.ipAddresses.hw4Tailscale;

  system.stateVersion = "23.11";

  systemd.slices = lib.mkMerge [
    (
      let
        inherit (builtins) listToAttrs;
        defaultScopes = [
          "init.scope"
          "system"
          "user"
          "machine"
        ];
      in
      listToAttrs (
        map (scope: {
          name = scope;
          value = {
            sliceConfig = {
              AllowedCPUs = "0-9,12-19";
            };
          };
        }) defaultScopes
      )
    )

    {
      "isolated" = {
        sliceConfig = {
          AllowedCPUs = "10-11";
        };
      };
    }
  ];

  home-manager.users.nelhage = import ./home-nelhage.nix;
}

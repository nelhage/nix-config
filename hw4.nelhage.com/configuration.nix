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

  home-manager.users.nelhage =
    { config, ... }:
    {
      imports = [ ../home-manager/litestream.nix ];

      garmindb.enable = true;
      garmindb.litestream.enable = true;
      garmindb.litestream.replicaRoot = "gcs://nelhage-data/garmin";

      age.secrets."gcloud.json" = {
        file = ../secrets/hw4-gcloud.json.age;
      };
      gcloud.enable = true;
      gcloud.project = "livegrep";
    };
}

{ config, constants, ... }:
{
  imports = [
    ../../home-manager/local-caddy.nix
  ];

  nelhage.sync.autocommit.enable = true;

  services.syncthing = {
    enable = true;
    settings.folders = {
      "${config.home.homeDirectory}/Sync" = {
        id = "default";
        devices = [
          "hw4"
          "mythique"
        ];
      };

      "${config.home.homeDirectory}/Calibre Library" = {
        id = "calibre";
        devices = [ "hw4" ];
      };
    };

    settings.devices = {
      hw4 = {
        addresses = [
          "tcp://${constants.ipAddresses.hw4Tailscale}:22000/"
        ];
        id = constants.syncthingDevices.hw4;
        autoAcceptFolders = true;
      };

      mythique = {
        id = constants.syncthingDevices.mythique;
      };
    };
  };
}

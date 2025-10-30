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

  security.acme.certs."lab.nelhage.com" = { };
  services.nginx.virtualHosts."lab.nelhage.com" = {
    useACMEHost = "lab.nelhage.com";
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://localhost:8002";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      '';
    };
  };

  home-manager.users.nelhage =
    { config, ... }:
    {
      imports = [
        ../home-manager/litestream.nix
        ../home-manager/jupyterlab.nix
      ];

      nelhage.jupyterlab.enable = true;
      nelhage.jupyterlab.extraConfig = ''
        c.ServerApp.allow_remote_access = True
      '';

      garmindb.enable = true;
      garmindb.litestream.enable = true;
      garmindb.litestream.replicaRoot = "gcs://nelhage-data/garmin";

      age.secrets."gcloud.json" = {
        file = ../secrets/hw4-gcloud.json.age;
      };
      gcloud.enable = true;
      gcloud.project = "livegrep";

      age.secrets."aws-credentials" = {
        file = ../secrets/hw4-aws-credentials.age;
      };
      nelhage.aws.enable = true;
    };
}

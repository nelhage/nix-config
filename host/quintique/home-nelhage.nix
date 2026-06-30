{ config, ... }:
{
  imports = [
    ../../home-manager/local-caddy.nix
  ];

  nelhage.sync.autocommit.enable = false;

  nelhage.local-caddy = {
    enable = true;
    gcpProject = "livegrep";
    sites = {
      "lab.nelhage.me" = 8002;
      "blog.nelhage.me" = 1313;
      "notebook.nelhage.me" = 1987;
    };
  };

  nelhage.jupyterlab.extraConfig = ''
    c.ServerApp.allow_remote_access = True
    c.ServerApp.trust_xheaders = True
  '';

  services.syncthing = {
    enable = true;
    settings.folders = {
      "${config.home.homeDirectory}/Sync" = {
        id = "default";
      };
    };

    settings.devices = {
      hw4 = {
        addresses = [
          "tcp://100.78.93.125:22000/"
        ];
        id = "UFKNXH2-ACWP52M-U5CVTSM-2OVDJOP-6YRP75Z-SD35MLQ-ULYFZDZ-Q5MUAQC";
        autoAcceptFolders = true;
      };
    };
  };
}

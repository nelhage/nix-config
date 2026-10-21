{ config, lib, ... }: {
  services.nginx.virtualHosts."calibre.nelhage.com" = lib.mkIf config.services.calibre-server.enable {
    useACMEHost = "nelhage.com";
    forceSSL = true;

    locations."/".proxyPass =
      "http://localhost:${builtins.toString config.services.calibre-server.port}";
  };

  services.calibre-server = {
    enable = true;
    host = "127.0.0.1";
    port = 3233;
    libraries = [ "/home/nelhage/Calibre/" ];
    user = "nelhage";
    group = "nelhage";
  };
  # Restart calibre-server whenever a library's metadata.db changes, so that
  # it picks up books added/edited elsewhere (e.g. via sync).
  systemd.paths.calibre-server-restart = lib.mkIf config.services.calibre-server.enable {
    wantedBy = [ "multi-user.target" ];
    pathConfig = {
      PathChanged = map (l: "${lib.removeSuffix "/" l}/metadata.db")
        config.services.calibre-server.libraries;
      TriggerLimitIntervalSec = "60s";
      TriggerLimitBurst = 5;
    };
  };
  systemd.services.calibre-server-restart = lib.mkIf config.services.calibre-server.enable {
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${config.systemd.package}/bin/systemctl try-restart calibre-server.service";
    };
  };

  services.oauth2-proxy.nginx.virtualHosts."calibre.nelhage.com" = {
    allowed_emails = [ "nelhage@nelhage.com" ];
  };
}

{ config, lib, ... }: {
  services.nginx.virtualHosts."calibre.nelhage.com" = lib.mkIf config.services.calibre-server.enable {
    useACMEHost = "calibre.nelhage.com";
    forceSSL = true;

    locations."/".proxyPass =
      "http://localhost:${builtins.toString config.services.calibre-server.port}";
  };

  security.acme.certs."calibre.nelhage.com" = { };
  services.calibre-server = {
    enable = true;
    host = "127.0.0.1";
    port = 3233;
    libraries = [ "/home/nelhage/Calibre/" ];
    user = "nelhage";
    group = "nelhage";
  };
  services.oauth2-proxy.nginx.virtualHosts."calibre.nelhage.com" = {
    allowed_emails = [ "nelhage@nelhage.com" ];
  };
}

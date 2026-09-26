{ ... }:
let
  sockDir = "/run/jupyterlab";
  sock = "${sockDir}/jupyter.sock";
in
{
  security.acme.certs."lab.nelhage.com" = { };

  # Expose lab.nelhage.com publicly, gated by Google login. The oauth2-proxy
  # engine lives in modules/oauth2-proxy.nix.
  services.oauth2-proxy.nginx.virtualHosts."lab.nelhage.com" = {
    allowed_emails = [ "nelhage@nelhage.com" ];
  };

  # Jupyter (running as nelhage) listens on a UNIX socket, and filesystem
  # permissions are the only access control: the directory is setgid nginx
  # and not world-accessible, so the socket is reachable only by nelhage and
  # nginx. Jupyter's own token auth is disabled; oauth2-proxy gates the
  # public path.
  systemd.tmpfiles.rules = [
    "d ${sockDir} 2750 nelhage nginx -"
  ];

  services.nginx.virtualHosts."lab.nelhage.com" = {
    useACMEHost = "lab.nelhage.com";
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://unix:${sock}";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      '';
      recommendedProxySettings = false;
    };
  };

  home-manager.users.nelhage = {
    nelhage.jupyterlab = {
      enable = true;
      inherit sock;
      # The socket inherits group nginx from the setgid directory.
      sockMode = "0660";
      extraConfig = ''
        c.ServerApp.allow_remote_access = True
        c.IdentityProvider.token = ""
      '';
    };
  };
}

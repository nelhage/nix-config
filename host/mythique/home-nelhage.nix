{ ... }:
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
      "syncthing.nelhage.me" = {
        port = 8384;
        # Syncthing's web UI refuses connections whose Host header isn't
        # localhost, so rewrite it on the way upstream.
        extraCaddyConfig = "header_up Host localhost";
      };
    };
  };

  nelhage.jupyterlab.extraConfig = ''
    c.ServerApp.allow_remote_access = True
    c.ServerApp.trust_xheaders = True
  '';
}

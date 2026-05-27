{ ... }:
{
  imports = [
    ../../home-manager/local-caddy.nix
  ];

  nelhage.sync.autocommit.enable = true;

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
}

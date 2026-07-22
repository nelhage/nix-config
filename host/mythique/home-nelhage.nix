{ ... }:
{
  imports = [
    ../../home-manager/local-caddy.nix
  ];

  nelhage.sync.autocommit.enable = false;

  nelhage.jupyterlab.extraConfig = ''
    c.ServerApp.allow_remote_access = True
    c.ServerApp.trust_xheaders = True
  '';
}

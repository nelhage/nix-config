{
  pkgs,
  ...
}:
{
  imports = [ ./jupyterlab.nix ];

  home.packages = [ pkgs.yubikey-manager ];

  nelhage.jupyterlab.enable = true;
}

{
  pkgs,
  ...
}:
{
  imports = [
    ./jupyterlab.nix
  ];

  home.packages = [ pkgs.yubikey-manager ];
  nelhage.dotfiles.symlink = true;

  nelhage.jupyterlab.enable = true;
}

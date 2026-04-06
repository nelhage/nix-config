{
  pkgs,
  ...
}:
{
  imports = [
    ./jupyterlab.nix
  ];

  home.packages = [ pkgs.yubikey-manager ];
  dotfiles.symlink = true;

  nelhage.jupyterlab.enable = true;
}

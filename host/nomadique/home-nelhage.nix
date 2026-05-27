{ pkgs, ... }:
{
  imports = [
    ../../modules/common.nix
    ../../home-manager/home.nix
    ../../home-manager/laptop.nix
  ];

  home.homeDirectory = "/home/nelhage/";
  fonts.fontconfig.enable = true;
  home.packages = [
    pkgs.nerd-fonts.fira-code
  ];

  nix.package = pkgs.nix;
}

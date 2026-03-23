{ pkgs, ... }:
{
  imports = [
    ../modules/common.nix
    ./home.nix
    ./laptop.nix
  ];

  home.homeDirectory = "/home/nelhage/";
  fonts.fontconfig.enable = true;
  home.packages = [
    pkgs.nerd-fonts.fira-code
  ];

  nix.package = pkgs.nix;
}

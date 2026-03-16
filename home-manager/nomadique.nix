{ pkgs, ... }:
{
  home.homeDirectory = "/home/nelhage/";
  imports = [
    ../modules/common.nix
    ./home.nix
    ./laptop.nix
  ];

  nix.package = pkgs.nix;
}

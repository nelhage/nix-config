{ pkgs, ... }:
{
    imports = [
    ../modules/common.nix
    ./home.nix
    ./laptop.nix
  ];

  home.homeDirectory = "/home/nelhage/";

  nix.package = pkgs.nix;
}

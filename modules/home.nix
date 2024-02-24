{ config, pkgs, ... }:

{
  home = {
    username = "nelhage";
    homeDirectory =
      if pkgs.stdenv.isLinux then "/home/nelhage" else "/Users/nelhage";

    stateVersion = "23.11";
    packages = import ./dev-pkgs.nix {inherit pkgs;};
  };

  programs.home-manager.enable = true;
}

{ config, pkgs, ... }:

{
  home = {
    username = "nelhage";

    stateVersion = "23.11";
    packages = with pkgs; [
      pv

      # N.B. see https://nixos.wiki/wiki/Google_Cloud_SDK
      google-cloud-sdk

      hugo
      gh

      starship
      tmux

      # Nix stuff
      nixfmt
      nixos-rebuild
      nil
    ];
  };

  programs.home-manager.enable = true;
}

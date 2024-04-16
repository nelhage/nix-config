{ config, pkgs, ... }:

{
  home = {
    username = "nelhage";

    stateVersion = "23.11";
    packages = with pkgs; [
      # N.B. see https://nixos.wiki/wiki/Google_Cloud_SDK
      google-cloud-sdk

      # Shell utilities and their ilk
      pv
      gh
      starship
      tmux
      ripgrep

      hugo

      # Language stuff
      pyenv
      go

      # Nix stuff
      nixfmt-rfc-style
      nixos-rebuild
      nil
    ];
  };

  programs = {
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };

  programs.home-manager.enable = true;
}

{ config, pkgs, ... }:

{
  imports = [ ./bin.nix ];

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
      tree

      hugo

      # Language stuff
      pyenv
      go
      nodejs_20

      # Development tools
      git

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

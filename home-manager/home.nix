{ config, pkgs, ... }:

{
  imports = [
    ./bin.nix
    ./dotfiles.nix
    ./sync.nix
    ./tailscale-completion.nix
  ];

  home = {
    username = "nelhage";

    stateVersion = "23.11";
    packages = with pkgs; [
      # Shell utilities and their ilk
      atuin
      base16-shell
      gh
      ispell
      mosh
      pv
      ripgrep
      starship
      tmux
      tree

      # Other tooling
      hugo
      ## N.B. see https://nixos.wiki/wiki/Google_Cloud_SDK
      google-cloud-sdk

      # Language stuff
      pyenv
      go
      nodejs_20

      # Development tools
      git

      # Nix stuff
      nix
      nix-zsh-completions
      nixfmt-rfc-style
      nixos-rebuild
      nil

      # My custom obsidian.el helper
      obsidian-scan
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

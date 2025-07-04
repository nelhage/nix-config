{ config, pkgs, ... }:

{
  imports = [
    ./dotfiles.nix
    ./sync.nix
    ./hugo-servers.nix
    ./obsidian-scan.nix
    ./tailscale-completion.nix
    ./gcloud.nix
    ./aws.nix
  ];

  home = {
    username = "nelhage";

    stateVersion = "23.11";
    packages = with pkgs; [
      # Shell utilities and their ilk
      atuin
      nelhage.base16-shell
      gh
      ispell
      (aspellWithDicts (
        dicts: with dicts; [
          en
          en-computers
          en-science
        ]
      ))
      mosh
      pv
      ripgrep
      starship
      tmux
      tree
      jq
      htop
      nelhage.scripts

      # Other tooling
      hugo
      ## N.B. see https://nixos.wiki/wiki/Google_Cloud_SDK
      google-cloud-sdk
      awscli
      s5cmd

      # Language stuff
      pyenv
      go
      nodejs_20
      cmake

      # Development tools
      git
      litestream
      sqlite-interactive
      duckdb
      rsync

      # Nix stuff
      nix
      nix-zsh-completions
      nixfmt-rfc-style
      nixos-rebuild
      nil
      agenix
    ];
  };

  programs = {
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };

  programs.home-manager.enable = true;

  systemd.user.startServices = "sd-switch";

  # I set EDITOR=$HOME/bin/edit instead of relying on $PATH. I forget
  # why that is, but just keep that path working.
  home.file.edit = {
    target = "bin/edit";
    source = "${pkgs.nelhage.scripts}/bin/edit";
  };
}

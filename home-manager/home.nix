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
    packages =
      with pkgs;
      let
        ghostty-pkg = if stdenv.hostPlatform.system == "aarch64-darwin" then ghostty-bin else ghostty;
      in
      [
        # Shell utilities and their ilk
        atuin
        nelhage.base16-shell
        gh
        ispell
        (
          let
            aspellDicts = pkgs.symlinkJoin {
              name = "aspell-dicts";
              paths = [
                pkgs.aspell
              ]
              ++ (with pkgs.aspellDicts; [
                en
                en-computers
                en-science
              ]);
            };
          in
          pkgs.writeShellScriptBin "aspell" ''
            export ASPELL_CONF="data-dir ${aspellDicts}/lib/aspell;"
            exec ${pkgs.aspell}/bin/aspell "$@"
          ''
        )

        mosh
        pv
        ripgrep
        starship
        tmux
        ghostty-pkg.terminfo
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
        gdu

        # Language stuff
        pyenv
        uv
        go
        nodejs_24
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
        nixfmt
        nixos-rebuild
        nil
        agenix
        age
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

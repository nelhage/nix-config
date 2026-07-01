{
  config,
  lib,
  pkgs,
  constants,
  ...

}:
let
  inherit (lib) types;
in
{
  imports = [
    ./agenix.nix
    ./nelhage-services
    ./nix-docsets.nix
    ./oauth2-proxy.nix
  ];

  options.nelhage = {
    tailscaleAddress = lib.mkOption {
      description = "This node's tailscale address";
      type = types.nullOr types.str;
      default = null;
    };
  };

  config = {
    services.openssh.enable = true;
    services.openssh.settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
    programs.mosh.enable = true;
    programs.zsh.enable = true;

    environment.systemPackages = map lib.lowPrio [
      pkgs.curl
      pkgs.gitMinimal
      pkgs.vim
      pkgs.man-pages
      pkgs.man-pages-posix
      pkgs.ghostty.terminfo
    ];

    environment.defaultPackages = [
      pkgs.emacs
      pkgs.strace
      pkgs.file
      pkgs.lsof
      pkgs.docker-compose
      pkgs.rsync
      pkgs.zsh
      pkgs.zip
      pkgs.unzip
      pkgs.ncdu
      pkgs.perf
      pkgs.nelhage.claude-code-wrapper
    ];

    users.users =
      let
        pubkeys = [
          constants.sshKeys."nelhage@mythique"
          constants.sshKeys."nelhage@pixel-ten"
          constants.sshKeys."nelhage@quintique"
          constants.sshKeys."nelhage@nomadique"
        ];
      in
      {
        root = {
          openssh.authorizedKeys.keys = pubkeys;
        };
        nelhage = {
          openssh.authorizedKeys.keys = pubkeys;
          extraGroups = [
            "wheel"
            "docker"
          ];
          group = "nelhage";
          uid = 1000;
          isNormalUser = true;
          description = "Nelson Elhage";
          shell = pkgs.zsh;
        };
      };

    users.groups.nelhage = {
      gid = 1000;
    };

    home-manager = {
      useGlobalPkgs = true;
      extraSpecialArgs = { inherit constants; };
      users.nelhage =
        { ... }:
        {
          imports = [
            ../home-manager/home.nix
            ../home-manager/nelhage.com.nix
          ];
        };
      backupFileExtension = "hm-backup";
    };

    security.sudo.extraConfig = "nelhage   ALL=(ALL:ALL) NOPASSWD: ALL";

    systemd.tmpfiles.rules = [
      "d /data/ 0755 root root"
      "d /data/git 0700 git git"
    ];

    services.gitolite = {
      enable = true;
      user = "git";
      group = "git";
      dataDir = "/data/git";
      adminPubkey = builtins.elemAt config.users.users.nelhage.openssh.authorizedKeys.keys 0;
      extraGitoliteRc = ''
        $RC{GIT_CONFIG_KEYS} = '.*';
        $RC{EXPAND_GROUPS_IN_CONFIG} = 1;
      '';
    };

    programs.git = {
      enable = true;
      config = {
        init = {
          defaultBranch = "main";
        };
      };
    };

    services.syncthing = {
      enable = true;
      user = "nelhage";
      dataDir = "/home/nelhage/Sync";
      configDir = "/home/nelhage/.config/syncthing";
      guiAddress = lib.mkIf (
        config.nelhage.tailscaleAddress != null
      ) "${config.nelhage.tailscaleAddress}:8384";
    };

    services.tailscale.enable = true;

    virtualisation.docker.enable = true;
    virtualisation.docker.daemon.settings = {
      data-root = "/data/docker";
    };
  };
}

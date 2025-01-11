{
  config,
  lib,
  pkgs,
  home-manager,
  ...
}:
{
  imports = [
    home-manager.nixosModules.default
    ./nelhage-services
    ./garmindb.nix
  ];

  services.openssh.enable = true;
  programs.mosh.enable = true;
  programs.zsh.enable = true;

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.gitMinimal
    pkgs.vim
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
  ];

  users.users =
    let
      pubkeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOj/9YTjI5Pr3TrzFMr9ADLTw7yeJZ6jCejXRL9N0rku nelhage@mythique"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIZA2k+GfubMI9WPc9tyX0Vw3xXvUOuaDcrdyNeAzfgf nelhage@pedagogique"
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
    users.nelhage =
      { ... }:
      {
        imports = [ ../home-manager/home.nix ];
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
  };

  services.syncthing = {
    enable = true;
    user = "nelhage";
    dataDir = "/home/nelhage/Sync";
    configDir = "/home/nelhage/.config/syncthing";
  };

  services.tailscale.enable = true;

  virtualisation.docker.enable = true;
  virtualisation.docker.daemon.settings = {
    data-root = "/data/docker";
  };
}

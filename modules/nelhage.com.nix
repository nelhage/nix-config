{
  config,
  lib,
  pkgs,
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
    programs.mosh.enable = true;
    programs.zsh.enable = true;

    environment.systemPackages = map lib.lowPrio [
      pkgs.curl
      pkgs.gitMinimal
      pkgs.vim
      pkgs.man-pages
      pkgs.man-pages-posix
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
      pkgs.linuxPackages_latest.perf
    ];

    users.users =
      let
        pubkeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOj/9YTjI5Pr3TrzFMr9ADLTw7yeJZ6jCejXRL9N0rku nelhage@mythique"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIZA2k+GfubMI9WPc9tyX0Vw3xXvUOuaDcrdyNeAzfgf nelhage@pedagogique"
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILAc21zLDUk1y2VP2AIUtKhGT5SUrmPN0xI4nFn7bqmU nelhage@pixel-ten"
          "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBFzLlWzdMDU5vbNJNEneUfSoOtMz7xEzfVnfFTvLl/atHO8qKBn97IwmOZwnnxYhEOfnbHk0JB/mA083yQQ2w+M= nelhage@anthropic-laptop"
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

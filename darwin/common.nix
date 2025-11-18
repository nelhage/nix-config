{ pkgs, lib, ... }:
{
  imports = [
    ../modules/common.nix
    ../modules/agenix.nix
  ];

  environment.systemPackages = [
    pkgs.coreutils-prefixed
  ];

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true; # default shell on catalina
  # programs.fish.enable = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  users.users.nelhage = {
    uid = 501;
    gid = 20;
    home = "/Users/nelhage";
    isHidden = false;
    description = "Nelson Elhage";
  };

  environment.etc."sudoers.d/01-nelhage" = {
    text = ''
      nelhage   ALL=(ALL:ALL) NOPASSWD: ALL
    '';
  };

  fonts.packages = [ pkgs.nerd-fonts.fira-code ];
  nix.optimise.automatic = true;

  launchd.daemons.linux-builder = {
    serviceConfig = {
      RunAtLoad = lib.mkForce false;
      KeepAlive = lib.mkForce false;
      StandardOutPath = "/var/log/linux-builder.log";
      StandardErrorPath = "/var/log/linux-builder.log";
    };
  };

  nix.linux-builder = {
    enable = false;
    ephemeral = true;
    maxJobs = 4;
    config = {
      virtualisation = {
        darwin-builder = {
          diskSize = 40 * 1024;
          memorySize = 8 * 1024;
        };
        cores = 6;
      };
      services.logind.extraConfig = builtins.concatStringsSep "\n" [
        "IdleAction=poweroff"
        "IdleActionSec=30m"
      ];
    };
  };
}

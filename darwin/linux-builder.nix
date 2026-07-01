{ lib, ... }: {
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

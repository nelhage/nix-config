{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) types;
  opts = config.sync;
  unit = "autocommit-sync";
in
{
  options = {
    sync.autocommit = {
      enable = lib.mkOption {
        type = types.bool;
        default = false;
        description = "Automatically git-commit the Sync directory";
      };

      interval = lib.mkOption {
        type = types.str;
        default = "10m";
        description = "Frequency of the autocommit job";
      };

      path = lib.mkOption {
        type = types.str;
        default = "${config.home.homeDirectory}/Sync";
        defaultText = "~/Sync";
        description = "Path to the Sync directory";
      };
    };
  };

  config = lib.mkIf opts.autocommit.enable {
    home.packages = [
      pkgs.bash
      pkgs.git
      pkgs.coreutils
      pkgs.nettools
    ];

    systemd.user.timers."${unit}" = {
      Unit = { };
      Timer = {
        OnStartupSec = "${opts.autocommit.interval}";
        OnUnitActiveSec = "${opts.autocommit.interval}";
      };
      Install = {
        WantedBy = [ "timers.target" ];
      };
    };
    systemd.user.services."${unit}" = {
      Unit = {
        Description = "Make a git commit of the ~/Sync directory";
      };
      Service = {
        Environment = "PATH=${config.home.profileDirectory}/bin";
        ExecStart = "${opts.autocommit.path}/scripts/git-commit.sh";
      };
    };
  };
}

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
        type = types.int;
        default = 10 * 60;
        description = "Interval between autocommit jobs, in seconds";
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
      Timer =
        let
          interval = "${builtins.toString opts.autocommit.interval}s";
        in
        {
          OnStartupSec = interval;
          OnUnitActiveSec = interval;
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

    launchd.agents."${unit}" = {
      enable = true;
      config = {
        ProgramArguments = [ "${opts.autocommit.path}/scripts/git-commit.sh" ];
        EnvironmentVariables = {
          PATH = "${config.home.profileDirectory}/bin";
        };
        WorkingDirectory = "${opts.autocommit.path}";
        StartInterval = opts.autocommit.interval;
      };
    };
  };
}

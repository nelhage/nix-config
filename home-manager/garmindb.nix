{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) types;
  opts = config.garmindb;
  unit = "garmindb-import";
in
{
  options.garmindb = {
    enable = lib.mkOption {
      type = types.bool;
      default = false;
      description = "Automatically git-commit the Sync directory";
    };

    schedule = lib.mkOption {
      type = types.str;
      default = "*-*-* 03:42:00";
      description = "systemd.time(7) calendar event to schedule the sync";
    };

    pkg = lib.mkOption {
      type = types.package;
      default = pkgs.callPackage ../pkgs/garmindb { };
      description = "garmindb package to use";
    };

    args = lib.mkOption {
      type = types.str;
      default = "--all --download --latest --import";
    };

    path = lib.mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/garmin/";
      defaultText = "~/garmin/";
      description = "Path to store imported Garmin data files.";
    };
  };

  config = lib.mkIf opts.enable {
    systemd.user.timers."${unit}" = {
      Timer = {
        OnCalendar = opts.schedule;
      };
      Install = {
        WantedBy = [ "timers.target" ];
      };
    };
    systemd.user.services."${unit}" = {
      Unit = {
        Description = "Import Garmin Connect data";
        After = [ "agenix.service" ];
      };
      Service = {
        WorkingDirectory = opts.path;
        ExecStart = "${opts.pkg}/bin/garmindb_cli.py ${opts.args}";
      };
    };

    age.secrets."GarminConnectConfig.json" = {
      file = ../secrets/GarminConnectConfig.json.age;
    };

    home.file = {
      "GarminConnectConfig.json" = {
        target = ".GarminDb/GarminConnectConfig.json";
        source = config.lib.file.mkOutOfStoreSymlink config.age.secrets."GarminConnectConfig.json".path;
      };
    };
  };
}

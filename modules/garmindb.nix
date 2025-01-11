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
      default = "${config.users.users.nelhage.home}/garmin/";
      defaultText = "~/garmin/";
      description = "Path to store imported Garmin data files.";
    };
  };

  config = lib.mkIf opts.enable {
    systemd.timers."${unit}" = {
      timerConfig = {
        OnCalendar = opts.schedule;
        Service = "${unit}";
      };
      wantedBy = [ "timers.target" ];
    };
    systemd.services."${unit}" = {
      description = "Import Garmin Connect data";
      serviceConfig = {
        User = "nelhage";
        WorkingDirectory = opts.path;
      };
      script = "${opts.pkg}/bin/garmindb_cli.py ${opts.args}";
    };

    age.secrets."GarminConnectConfig.json" = {
      file = ../secrets/GarminConnectConfig.json.age;
      owner = "nelhage";
    };

    home-manager.users.nelhage =
      let
        secretPath = config.age.secrets."GarminConnectConfig.json".path;
      in
      { config, ... }:
      {
        home.file = {
          "GarminConnectConfig.json" = {
            target = ".GarminDb/GarminConnectConfig.json";
            source = config.lib.file.mkOutOfStoreSymlink secretPath;
          };
        };
      };
  };
}

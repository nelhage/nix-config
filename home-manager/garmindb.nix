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

    litestream = lib.mkOption {
      type = types.submodule {
        options = {
          enable = lib.mkOption {
            type = types.bool;
            default = false;
            description = "Use litestream to replicate the DBs to cloud storage.";
          };

          replicaRoot = lib.mkOption {
            type = types.str;
            description = "Base path to replica DBs to";
          };
        };
      };
    };

    args = lib.mkOption {
      type = types.str;
      default = "--all --download --latest --import";
    };

    path = lib.mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/garmin";
      defaultText = "~/garmin";
      description = "Path to store imported Garmin data files.";
    };
  };

  config = lib.mkIf opts.enable {
    programs.litestream = lib.mkIf opts.litestream.enable {
      enable = true;

      databases =
        lib.attrsets.genAttrs [ "garmin.db" "garmin_activities.db" "garmin_monitoring.db" ]
          (db: {
            path = "${opts.path}/DBs/${db}";
            replicas = [
              {
                url = "${opts.litestream.replicaRoot}/${db}";
              }
            ];
          });
    };

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

    age.secrets."garmin.password" = {
      file = ../secrets/garmin.password.age;
    };

    home.file =
      let
        GarminConnectConfig = {
          activities = {
            display = [ ];
          };
          course_views = {
            steps = [ ];
          };
          credentials = {
            password = null;
            secure_password = false;
            user = "nelhage@nelhage.com";
            password_file = "${config.age.secrets."garmin.password".path}";
          };
          data = {
            download_all_activities = 1000;
            download_latest_activities = 25;
            monitoring_start_date = "01/20/2020";
            rhr_start_date = "01/20/2020";
            sleep_start_date = "01/20/2020";
            weight_start_date = "11/14/2023";
          };
          directories = {
            base_dir = "${opts.path}";
            mount_dir = "/Volumes/GARMIN";
            relative_to_home = false;
          };
          enabled_stats = {
            activities = true;
            itime = true;
            monitoring = true;
            rhr = true;
            sleep = true;
            steps = true;
            weight = false;
          };
          garmin = {
            domain = "garmin.com";
          };
          modes = { };
        };
      in
      {
        "GarminConnectConfig.json" = {
          target = ".GarminDb/GarminConnectConfig.json";
          text = builtins.toJSON GarminConnectConfig;
        };
      };
  };
}

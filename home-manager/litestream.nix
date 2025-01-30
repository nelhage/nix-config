# This file was written by Claude, probably ask him for edits
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.programs.litestream;

  # Types for replica configuration
  replicaOptions = types.submodule {
    options = {
      type = mkOption {
        type = types.nullOr (
          types.enum [
            "s3"
            "file"
            "abs"
          ]
        );
        default = null;
        description = "Type of replica (s3, file, or Azure Blob Storage). Optional when URL is provided.";
      };

      name = mkOption {
        type = types.str;
        default = "";
        description = "Unique name for the replica. Defaults to the replica type if not specified.";
      };

      url = mkOption {
        type = types.str;
        default = "";
        description = "Short-hand form of specifying a replica location";
      };

      retention = mkOption {
        type = types.str;
        default = "24h";
        description = "How long snapshots and WAL files are kept";
      };

      retentionCheckInterval = mkOption {
        type = types.str;
        default = "1h";
        description = "How often to check if retention needs to be enforced";
      };

      snapshotInterval = mkOption {
        type = types.str;
        default = "";
        description = "How often new snapshots should be created";
      };

      validationInterval = mkOption {
        type = types.str;
        default = "";
        description = "Interval for validating replica data against local copy";
      };

      syncInterval = mkOption {
        type = types.str;
        default = "1s";
        description = "Frequency in which frames are pushed to the replica";
      };

      # S3-specific options
      bucket = mkOption {
        type = types.str;
        default = "";
        description = "S3 bucket name";
      };

      path = mkOption {
        type = types.str;
        default = "";
        description = "Path within bucket or filesystem";
      };

      region = mkOption {
        type = types.str;
        default = "";
        description = "AWS region";
      };

      accessKeyId = mkOption {
        type = types.str;
        default = "";
        description = "AWS access key ID";
      };

      secretAccessKey = mkOption {
        type = types.str;
        default = "";
        description = "AWS secret access key";
      };

      endpoint = mkOption {
        type = types.str;
        default = "";
        description = "Custom endpoint for S3-compatible services";
      };

      forcePathStyle = mkOption {
        type = types.bool;
        default = false;
        description = "Use path-style S3 URLs";
      };

      skipVerify = mkOption {
        type = types.bool;
        default = false;
        description = "Skip TLS verification";
      };
    };
  };

  # Types for database configuration
  databaseOptions = types.submodule {
    options = {
      path = mkOption {
        type = types.str;
        description = "Path to the SQLite database file";
      };

      replicas = mkOption {
        type = types.listOf replicaOptions;
        default = [ ];
        description = "List of replicas for this database";
      };
    };
  };

  # Helper functions to clean up empty values
  removeEmpty = attrs: filterAttrs (n: v: v != null && v != "" && v != [ ] && v != { }) attrs;

  cleanUpReplica =
    replica:
    removeEmpty {
      type = replica.type;
      name = replica.name;
      url = replica.url;
      retention = replica.retention;
      "retention-check-interval" = replica.retentionCheckInterval;
      "snapshot-interval" = replica.snapshotInterval;
      "validation-interval" = replica.validationInterval;
      "sync-interval" = replica.syncInterval;
      bucket = replica.bucket;
      path = replica.path;
      region = replica.region;
      "access-key-id" = replica.accessKeyId;
      "secret-access-key" = replica.secretAccessKey;
      endpoint = replica.endpoint;
      "force-path-style" = if replica.forcePathStyle then true else null;
      "skip-verify" = if replica.skipVerify then true else null;
    };

  # Convert the config to YAML format
  yamlFormat = pkgs.formats.yaml { };

  # Generate the Litestream config file
  configFile = yamlFormat.generate "litestream.yml" (removeEmpty {
    addr = cfg.metricsAddr;

    logging = removeEmpty {
      level = cfg.logging.level;
      type = cfg.logging.type;
      stderr = if cfg.logging.stderr then true else null;
    };

    access-key-id = cfg.globalAccessKeyId;
    secret-access-key = cfg.globalSecretAccessKey;

    dbs = map (
      name:
      removeEmpty {
        path = cfg.databases.${name}.path;
        replicas = map cleanUpReplica cfg.databases.${name}.replicas;
      }
    ) (attrNames cfg.databases);
  });

in
{
  options.programs.litestream = {
    enable = mkEnableOption "Litestream SQLite replication";

    package = mkOption {
      type = types.package;
      default = pkgs.litestream;
      defaultText = literalExpression "pkgs.litestream";
      description = "The Litestream package to use";
    };

    metricsAddr = mkOption {
      type = types.str;
      default = "";
      description = "Address to expose Prometheus metrics";
    };

    globalAccessKeyId = mkOption {
      type = types.str;
      default = "";
      description = "Global AWS access key ID";
    };

    globalSecretAccessKey = mkOption {
      type = types.str;
      default = "";
      description = "Global AWS secret access key";
    };

    logging = {
      level = mkOption {
        type = types.enum [
          "debug"
          "info"
          "warn"
          "error"
        ];
        default = "info";
        description = "Logging level";
      };

      type = mkOption {
        type = types.enum [
          "text"
          "json"
        ];
        default = "text";
        description = "Logging output format";
      };

      stderr = mkOption {
        type = types.bool;
        default = false;
        description = "Write logs to stderr instead of stdout";
      };
    };

    databases = mkOption {
      type = types.attrsOf databaseOptions;
      default = { };
      description = "Litestream database configurations";
    };
  };

  config = mkIf cfg.enable {
    xdg.configFile."litestream.yml".source = configFile;

    systemd.user.services.litestream = {
      Unit = {
        Description = "Litestream SQLite replication service";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
        X-Restart-Triggers = [ configFile ];
      };

      Service = {
        ExecStart = "${cfg.package}/bin/litestream replicate -config %h/.config/litestream.yml";
        Restart = "always";
        RestartSec = "10";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}

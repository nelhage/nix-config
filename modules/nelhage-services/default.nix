{
  config,
  lib,
  pkgs,
  ...
}:
let
  config-package = (
    pkgs.callPackage ./config-package.nix {
      credentials = config.age.secrets."nelhage-services.yaml".path;
    }
  );
  indexes = [
    "ml"
    "linux"
  ];

  crossme-backup =
    let
      database = "/data/crossme/crossme.db";
      # A single fixed object, overwritten in place each run; we want the
      # latest snapshot, not a history. Replacing a GCS object is atomic, so a
      # concurrent reader sees either the old or the new copy, never a partial.
      destination = "gs://nelhage-data/crossme/crossme.db.zst";
      # Tables holding only transient state; their contents are dropped from
      # the snapshot. `sessions` is live login tokens, which are useless in a
      # backup and are a credential we'd rather not copy off the box.
      transient = [ "sessions" ];
      strip = lib.concatMapStrings (table: "DELETE FROM ${table};\n") transient + "VACUUM;";
    in
    pkgs.writeShellApplication {
      name = "crossme-backup";
      runtimeInputs = with pkgs; [
        google-cloud-sdk
        sqlite
        zstd
      ];
      text = ''
        # systemd gives us a fresh RuntimeDirectory per start, so VACUUM INTO
        # (which refuses to overwrite) always sees a clean target.
        snapshot="$RUNTIME_DIRECTORY/crossme.db"

        # VACUUM INTO runs in a single read transaction, so this is a
        # consistent snapshot (WAL included) that doesn't block the server.
        # -init /dev/null: ignore any ~/.sqliterc, which could otherwise change
        # the output format out from under the integrity check below.
        sqlite3 -init /dev/null ${database} "VACUUM INTO '$snapshot'"
        sqlite3 -init /dev/null "$snapshot" ${lib.escapeShellArg strip}
        test "$(sqlite3 -init /dev/null "$snapshot" 'PRAGMA integrity_check')" = ok

        zstd -19 --rm -q "$snapshot"

        export CLOUDSDK_CONFIG="$RUNTIME_DIRECTORY/gcloud"
        export CLOUDSDK_CORE_PROJECT=livegrep
        gcloud auth login --quiet --cred-file=${config.age.secrets."crossme-backup-gcloud.json".path}
        gcloud storage cp "$snapshot.zst" "${destination}"
      '';
    };
in
{
  environment.systemPackages = [
    config-package
  ];

  age.secrets."nelhage-services.yaml" = {
    file = ../../secrets/nelhage-services.age;
    owner = "nelhage";
  };
  # The same credentials home-manager gives nelhage's gcloud, but owned by root
  # so the backup timer can use them outside of a user session.
  age.secrets."crossme-backup-gcloud.json" = {
    file = ../../secrets/hw4-gcloud.json.age;
  };
  age.secrets."gcp-service.json" = {
    file = ../../secrets/gcp-service.json.age;
    owner = "acme";
    group = "nginx";
    mode = "0440";
  };

  systemd.services =
    builtins.listToAttrs (
      builtins.map (
        name:
        lib.attrsets.nameValuePair "livegrep-reindex-${name}" {
          description = "Regenerate the livegrep ${name} index.";
          script = "${config-package.binary} up -d livegrep-indexer-${name}";
          serviceConfig = {
            User = "nelhage";
          };
        }
      ) indexes
    )
    // {
      crossme-backup = {
        description = "Snapshot the CrossMe database to Google Cloud Storage.";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = lib.getExe crossme-backup;
          RuntimeDirectory = "crossme-backup";
          RuntimeDirectoryMode = "0700";
        };
      };
    };

  systemd.timers =
    builtins.listToAttrs (
      builtins.map (
        name:
        lib.attrsets.nameValuePair "livegrep-reindex-${name}" {
          wantedBy = [ "timers.target" ];
          after = [
            "time-set.target"
            "time-sync.target"
          ];
          timerConfig = {
            OnCalendar = "*-*-03 12:00:00";
            Service = "livegrep-reindex-${name}";
          };
        }
      ) indexes
    )
    // {
      crossme-backup = {
        wantedBy = [ "timers.target" ];
        after = [
          "time-set.target"
          "time-sync.target"
        ];
        timerConfig = {
          OnCalendar = "*-*-* 05,17:00:00";
          RandomizedDelaySec = "15m";
          Persistent = true;
          Service = "crossme-backup.service";
        };
      };
    };

  security.acme =
    let
      acmeEnvironment = pkgs.writeText "acme-env" ''
        GCE_PROJECT=livegrep
        GOOGLE_APPLICATION_CREDENTIALS=/run/agenix/gcp-service.json
      '';
    in
    {
      acceptTerms = true;
      defaults = {
        dnsProvider = "gcloud";
        email = "nelhage@nelhage.com";
        environmentFile = acmeEnvironment;
        group = "nginx";

        # Staging server for use during development:
        # server = "https://acme-staging-v02.api.letsencrypt.org/directory";
      };
      certs = {
        "nelhage.com" = {
          extraDomainNames = [ "www.nelhage.com" ];
        };
        "livegrep.com" = {
          extraDomainNames = [ "www.livegrep.com" ];
        };
        "crossme.app" = {
          extraDomainNames = [ "beta.crossme.app" ];
        };
      };
    };
  networking.firewall.allowedTCPPorts = [
    config.services.nginx.defaultHTTPListenPort
    config.services.nginx.defaultSSLListenPort
  ];

  services.nginx =
    let
      hstsConfig = ''
        add_header Expect-CT "enforce, max-age=31536000";
        add_header Strict-Transport-Security "max-age=31557600; preload; includeSubDomains";
      '';
    in
    {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      /*
        defaultHTTPListenPort = 8080;
        defaultSSLListenPort = 4443;
      */

      virtualHosts = {
        "_" = {
          default = true;
          rejectSSL = true;
          locations."/".return = "404";
        };

        "nelhage.com" = {
          useACMEHost = "nelhage.com";
          forceSSL = true;

          root = "/data/www/nelhage.com";

          extraConfig = hstsConfig + ''
            charset utf-8;
            absolute_redirect off;
            server_tokens off;
          '';

          locations."/blog".extraConfig = ''
            rewrite ^/blog(/.*)? https://blog.nelhage.com$1;
          '';

          locations."~ \"^/(git|bughunting|files/(stars|Troy)|poc\\|\\|gtfo)\"".extraConfig = ''
            autoindex on;
          '';

          locations."~ \"^/f/.+/\"".extraConfig = ''
            autoindex on;
          '';

          locations."/paste/".extraConfig = ''
            default_type text/plain;
          '';

          locations."/.git".extraConfig = ''
            return 404;
          '';
        };
        "www.nelhage.com" = {
          useACMEHost = "nelhage.com";
          addSSL = true;

          extraConfig = hstsConfig;

          locations."/".return = ''301 "https://nelhage.com$request_uri"'';
        };

        "livegrep.com" = {
          useACMEHost = "livegrep.com";
          forceSSL = true;

          extraConfig = hstsConfig;

          locations."/".proxyPass = "http://localhost:9002";
        };
        "www.livegrep.com" = {
          useACMEHost = "livegrep.com";
          addSSL = true;

          extraConfig = hstsConfig;

          locations."/".return = ''301 "https://livegrep.com$request_uri"'';
        };

        "crossme.app" = {
          useACMEHost = "crossme.app";
          forceSSL = true;

          extraConfig = hstsConfig;

          locations."/".proxyPass = "http://localhost:9003";
        };

        "beta.crossme.app" = {
          useACMEHost = "crossme.app";
          forceSSL = true;

          extraConfig = hstsConfig;

          locations."/".return = ''301 "https://crossme.app$request_uri"'';
        };
      };
    };
}

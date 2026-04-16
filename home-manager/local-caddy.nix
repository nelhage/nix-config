{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) types;
  opts = config.nelhage.local-caddy;
  unit = "local-caddy";

  caddyWithDns = pkgs.caddy.withPlugins {
    plugins = [ "github.com/caddy-dns/googleclouddns@v1.1.0" ];
    hash = "sha256-JqkqNEJlcy69lzhI0kU+Rsr2a1vWVlsM7IzdUpw9LA0=";
  };

  caddyfile = pkgs.writeText "Caddyfile" (
    lib.concatStringsSep "\n\n" (
      lib.mapAttrsToList (
        domain: port:
        ''
          ${domain} {
            reverse_proxy localhost:${toString port} {
              flush_interval -1
            }
            tls {
              dns googleclouddns {
                gcp_project ${opts.gcpProject}
              }
            }
          }
        ''
      ) opts.sites
    )
  );

  caddyArgs = [
    "${caddyWithDns}/bin/caddy"
    "run"
    "--config"
    "${caddyfile}"
    "--adapter"
    "caddyfile"
  ];
in
{
  options.nelhage.local-caddy = {
    enable = lib.mkOption {
      type = types.bool;
      default = false;
      description = "Run a local Caddy server that reverse-proxies to local services with TLS via GCP DNS ACME.";
    };

    sites = lib.mkOption {
      type = types.attrsOf types.port;
      default = { };
      description = "Mapping of domain names to local ports to reverse-proxy.";
      example = {
        "jupyter.example.com" = 8002;
        "notes.example.com" = 1987;
      };
    };

    gcpProject = lib.mkOption {
      type = types.str;
      description = "GCP project ID for Cloud DNS ACME challenges.";
    };

    dataDir = lib.mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/.local/share/caddy";
      description = "Directory for Caddy to store certificates and other data.";
    };
  };

  config = lib.mkIf opts.enable {
    systemd.user.services."${unit}" = {
      Unit = {
        Description = "Local Caddy reverse proxy with TLS";
      };
      Service = {
        Environment = [
          "XDG_DATA_HOME=${opts.dataDir}"
          "GOOGLE_APPLICATION_CREDENTIALS=${config.age.secrets."gcp-service.json".path}"
        ];
        ExecStart = lib.escapeShellArgs caddyArgs;
        Restart = "always";
        RestartSec = "10";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    launchd.agents."${unit}" =
      let
        logdir = "${config.home.homeDirectory}/Library/Logs";
      in
      {
        enable = true;
        config = {
          Label = "com.nelhage.${unit}";
          ProgramArguments = caddyArgs;

          EnvironmentVariables = {
            XDG_DATA_HOME = opts.dataDir;
            HOME = config.home.homeDirectory;
          };

          KeepAlive = true;
          RunAtLoad = true;

          StandardErrorPath = "${logdir}/${unit}-stderr.log";
          StandardOutPath = "${logdir}/${unit}-stdout.log";
        };
      };

    age.secrets."gcp-service.json" = {
      file = ../secrets/gcp-service.json.age;
    };
  };
}

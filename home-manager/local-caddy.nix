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
    hash = "sha256-oj4m3W5yiXNRZSI4Bnbpy2irIsF7A+cnWMR3ep9RvAw=";
  };

  # Normalize each site value to an attrset, so a bare port is treated as
  # `{ port = <port>; }`.
  normalizeSite = site: if builtins.isInt site then { port = site; } else site;

  caddyfile = pkgs.writeText "Caddyfile" (
    lib.concatStringsSep "\n\n" (
      lib.mapAttrsToList (
        domain: rawSite:
        let
          site = normalizeSite rawSite;
        in
        ''
          ${domain} {
            reverse_proxy localhost:${toString site.port} {
              flush_interval -1
              ${site.extraCaddyConfig or ""}
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
      type = types.attrsOf (
        types.either types.port (
          types.submodule {
            options = {
              port = lib.mkOption {
                type = types.port;
                description = "Local port to reverse-proxy to.";
              };
              extraCaddyConfig = lib.mkOption {
                type = types.lines;
                default = "";
                description = "Extra directives to include in this site's `reverse_proxy` block.";
              };
            };
          }
        )
      );
      default = { };
      description = ''
        Mapping of domain names to local ports to reverse-proxy. Each value may
        be either a bare port, or an attribute set with a mandatory `port` and an
        optional `extraCaddyConfig` string of additional Caddyfile directives.
      '';
      example = {
        "jupyter.example.com" = 8002;
        "notes.example.com" = {
          port = 1987;
          extraCaddyConfig = "header_up Host localhost";
        };
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

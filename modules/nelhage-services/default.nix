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
in
{
  environment.systemPackages = [
    config-package
  ];

  age.secrets."nelhage-services.yaml" = {
    file = ../../secrets/nelhage-services.age;
    owner = "nelhage";
  };
  age.secrets."gcp-service.json" = {
    file = ../../secrets/gcp-service.json.age;
    owner = "nelhage";
    mode = "0444";
  };

  systemd.services = builtins.listToAttrs (
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
  );

  systemd.timers = builtins.listToAttrs (
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
  );

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
      recommendedZstdSettings = true;
      recommendedOptimisation = true;
      /*
        defaultHTTPListenPort = 8080;
        defaultSSLListenPort = 4443;
      */

      virtualHosts = {
        "nelhage.com" = {
          useACMEHost = "nelhage.com";
          forceSSL = true;
          default = true;

          extraConfig = hstsConfig;

          locations."/".proxyPass = "http://localhost:9001";
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
      };
    };
}

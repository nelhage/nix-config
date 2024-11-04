{
  config,
  lib,
  pkgs,
  ...
}:
let
  config-package = (pkgs.callPackage ./config-package.nix {
    credentials = config.age.secrets."nelhage-services.yaml".path;
  });
  indexes = ["ml" "linux"];
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
    builtins.map (name: lib.attrsets.nameValuePair "livegrep-reindex-${name}" {
      description = "Regenerate the livegrep ${name} index.";
      script = "${config-package.binary} up -d livegrep-indexer-${name}";
      serviceConfig = {
        User="nelhage";
      };
    }) indexes);

  systemd.timers = builtins.listToAttrs (
    builtins.map (name: lib.attrsets.nameValuePair "livegrep-reindex-${name}" {
      wantedBy = [ "timers.target" ];
      after = [ "time-set.target" "time-sync.target" ];
      timerConfig = {
        OnCalendar = "*-*-03 12:00:00";
        Service = "livegrep-reindex-${name}";
      };
    }) indexes);
}

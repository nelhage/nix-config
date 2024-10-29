{
  config,
  lib,
  pkgs,
  ...
}:
let
  config-package = (pkgs.callPackage ./config-package.nix {});
  indexes = ["ml" "linux"];
in
{
  environment.systemPackages = [
    config-package
  ];

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

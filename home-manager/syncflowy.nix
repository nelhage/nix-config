{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) types;
  opts = config.nelhage.syncflowy;
  unit = "syncflowy";
in
{
  options.nelhage.syncflowy = {
    enable = lib.mkOption {
      type = types.bool;
      default = false;
      description = "Run the syncflowy Workflowy <-> Obsidian sync daemon";
    };

    pkg = lib.mkOption {
      type = types.package;
      default = pkgs.nelhage.syncflowy;
      description = "syncflowy package to use";
    };

    vault = lib.mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/Obsidian/nelhage";
      defaultText = "~/Obsidian/nelhage";
      description = "Path to the Obsidian vault to sync";
    };

    statusNote = lib.mkOption {
      type = types.str;
      default = "Workflowy/Sync Status.md";
      description = "Path of the status note, relative to the vault";
    };

    extraArgs = lib.mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Extra arguments to pass to `syncflowy daemon`";
    };
  };

  config = lib.mkIf opts.enable {
    home.packages = [ opts.pkg ];

    # An EnvironmentFile containing `WORKFLOWY_API_KEY=...`
    age.secrets."workflowy.env" = {
      file = ../secrets/workflowy.env.age;
    };

    systemd.user.services."${unit}" = {
      Unit = {
        Description = "syncflowy Workflowy <-> Obsidian sync daemon";
        After = [
          "agenix.service"
          "network-online.target"
        ];
        Requires = [ "agenix.service" ];
      };
      Service = {
        EnvironmentFile = config.age.secrets."workflowy.env".path;
        ExecStart = lib.escapeShellArgs (
          [
            "${opts.pkg}/bin/syncflowy"
            "-v"
            "daemon"
            "--vault"
            opts.vault
            "--status-note"
            opts.statusNote
          ]
          ++ opts.extraArgs
        );
        Restart = "always";
        RestartSec = 30;
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}

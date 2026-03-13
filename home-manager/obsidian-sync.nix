{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) types;
  opts = config.nelhage.obsidian-sync;
  unit = "obsidian-sync";
in
{
  options = {
    nelhage.obsidian-sync = {
      enable = lib.mkOption {
        type = types.bool;
        default = false;
        description = "Run obsidian-headless sync continuously";
      };

      path = lib.mkOption {
        type = types.str;
        default = "${config.home.homeDirectory}/Obsidian/nelhage";
        defaultText = "~/Obsidian/nelhage";
        description = "Path to the Obsidian vault";
      };

      version = lib.mkOption {
        type = types.str;
        default = "0.0.6";
        description = "Version of obsidian-headless to use";
      };
    };
  };

  config = lib.mkIf opts.enable {
    home.packages = [
      pkgs.nodejs
    ];

    systemd.user.services."${unit}" = {
      Unit = {
        Description = "Obsidian headless sync";
        After = [ "network-online.target" ];
      };
      Service = {
        Environment = "PATH=${
          lib.makeBinPath [
            pkgs.nodejs
            pkgs.python3
            pkgs.gnumake
            pkgs.gcc
            pkgs.coreutils
            pkgs.bash
          ]
        }:${config.home.profileDirectory}/bin";
        ExecStart = "${pkgs.nodejs}/bin/npx --yes obsidian-headless@${opts.version} sync --continuous --path ${opts.path}";
        Restart = "always";
        RestartSec = 10;
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}

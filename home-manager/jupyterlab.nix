{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) types;
  opts = config.nelhage.jupyterlab;
  unit = "jupyterlab";
in
{
  options.nelhage.jupyterlab = {
    enable = lib.mkOption {
      type = types.bool;
      default = false;
      description = "Run a jupyterlab server";
    };

    root_dir = lib.mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}";
      description = "jupyterlab root dir";
    };

    pkg = lib.mkOption {
      type = types.package;
      default = pkgs.nelhage.jupyterlab;
      description = "Package containing jupyterlab and any other desired Python dependencies";
    };

    bind = lib.mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Address to listen on";
    };

    port = lib.mkOption {
      type = types.int;
      default = 8002;
      description = "Port to listen on";
    };
  };

  config = lib.mkIf opts.enable (
    let
      inherit (lib.strings) escapeShellArgs;
      inherit (builtins) toString;
      configFile = pkgs.writeText "jupyter_lab_config.py" ''
        c = get_config()
        c.LabServerApp.open_browser = False
        c.ServerApp.root_dir = '${opts.root_dir}'
        c.ServerApp.ip = '${opts.bind}'
        c.ServerApp.port = ${toString opts.port}
      '';
    in
    {
      systemd.user.services."${unit}" = {
        Unit = {
          Description = "Run a jupyterlab server";
        };
        Service = {
          Environment = "PATH=${config.home.profileDirectory}/bin";
          ExecStart = escapeShellArgs [
            "${opts.pkg}/bin/jupyter"
            "lab"
            "--config=${configFile}"
          ];
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };
    }
  );
}

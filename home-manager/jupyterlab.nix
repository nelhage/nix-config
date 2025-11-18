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

    extraConfig = lib.mkOption {
      type = types.str;
      default = "";
      description = "Extra configuration in the jupyterlab config file.";
    };
    path = lib.mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Directories to add to the server's $PATH";
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
        ${opts.extraConfig}
      '';
    in
    {
      nelhage.jupyterlab.path = [
        "${config.home.profileDirectory}/bin"
        "${pkgs.ruff}/bin"
        "${opts.pkg}/bin"
      ];

      systemd.user.services."${unit}" = {
        Unit = {
          Description = "Run a jupyterlab server";
        };
        Service = {
          Environment = "PATH=${lib.strings.concatStringsSep ":" opts.path}";
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

      launchd.agents."${unit}" =
        let
          logdir = "${config.home.homeDirectory}/Library/Logs";
        in
        {
          enable = true;
          config = {
            Label = "com.nelhage.${unit}";
            ProgramArguments = [
              "${opts.pkg}/bin/jupyter"
              "lab"
              "--config=${configFile}"
            ];

            WorkingDirectory = "${opts.root_dir}";
            KeepAlive = true;
            RunAtLoad = true;

            StandardErrorPath = "${logdir}/${unit}-stdout.log";
            StandardOutPath = "${logdir}/${unit}-stderr.log";
          };
        };
    }
  );
}

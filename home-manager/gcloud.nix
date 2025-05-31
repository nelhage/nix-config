{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) types;
  opts = config.gcloud;

  credential_file = config.age.secrets.${opts.secret}.path;
  loginScript =
    let
      setProject = if opts.project != null then "gcloud config set project ${opts.project}" else "";
      app = pkgs.writeShellApplication {
        name = "gcloud-activate-service-account";
        runtimeInputs = with pkgs; [
          coreutils
          google-cloud-sdk
        ];
        text = ''
          ${setProject}
          gcloud auth login --cred-file=${credential_file}
          exit 0
        '';
      };
    in
    lib.getExe app;
  gs5cmd = pkgs.writeScriptBin "gs5cmd" ''
    #!/bin/sh
    exec ${pkgs.s5cmd}/bin/s5cmd --endpoint-url https://storage.googleapis.com --profile gcs "$@"
  '';
in
{
  options = {
    gcloud = {
      enable = lib.mkOption {
        type = types.bool;
        default = false;
        description = "Log in to gcloud using provided credentials";
      };

      secret = lib.mkOption {
        type = types.str;
        default = "gcloud.json";
        description = "Name of an age secret containing gcloud credentials.";
      };

      project = lib.mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Configure the gcloud default project.";
      };
    };
  };

  config = lib.mkIf opts.enable {
    xdg.configFile.gcloud-adc = {
      target = "gcloud/application_default_credentials.json";
      source = config.lib.file.mkOutOfStoreSymlink credential_file;
    };
    systemd.user.services.gcloud-login = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      Unit = {
        Description = "gcloud credential activation";
      };
      Service = {
        Type = "oneshot";
        ExecStart = loginScript;
        Requires = [ "agenix.service" ];
        After = [
          "agenix.service"
          "network-online.target"
        ];
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
    home.packages = [ gs5cmd ];
  };
}

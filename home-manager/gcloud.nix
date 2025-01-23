{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) types;
  opts = config.gcloud;

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
          gcloud auth login --cred-file=${config.age.secrets.${opts.secret}.path}
          exit 0
        '';
      };
    in
    lib.getExe app;
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
  };
}

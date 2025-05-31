{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) types;
  opts = config.nelhage.aws;

  credential_file = config.age.secrets.${opts.secret}.path;
in
{
  options.nelhage.aws = {
    enable = lib.mkOption {
      type = types.bool;
      default = false;
      description = "Install and configure AWS";
    };

    secret = lib.mkOption {
      type = types.str;
      default = "aws-credentials";
      description = "Name of an age secret containing AWS credentials.";
    };

    region = lib.mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "AWS default region";
    };
  };

  config =
    let
      awsConfig = ''
        [default]
        ${if opts.region == null then "" else "region = ${opts.region}"}
      '';
    in
    lib.mkIf opts.enable {
      home.file."aws-credentials" = {
        target = ".aws/credentials";
        source = config.lib.file.mkOutOfStoreSymlink credential_file;
      };
      home.file."aws-config" = {
        target = ".aws/config";
        text = awsConfig;
      };
    };
}

let
  constants = import ../constants.nix;
  keys = constants.sshKeys;
  me = [
    keys."nelhage@mythique"
    keys."nelhage@nomadique"
    keys."nelhage@quintique"
  ];
  nelhage_com = [ keys.hw4 ];
in
{
  "hw4-gcloud.json.age".publicKeys = nelhage_com ++ me;
  "hw4-aws-credentials.age".publicKeys = nelhage_com ++ me;
  "nelhage-services.age".publicKeys = nelhage_com ++ me;
  "gcp-service.json.age".publicKeys = nelhage_com ++ me;
  "garmin.password.age".publicKeys = nelhage_com ++ me;
  "oauth2-proxy.env.age".publicKeys = nelhage_com ++ me;
  "jupyter-auth.age".publicKeys = nelhage_com ++ me;
}

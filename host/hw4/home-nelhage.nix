{ config, pkgs, ... }:
{
  imports = [
    ../../home-manager/litestream.nix
    ../../home-manager/jupyterlab.nix
    ../../home-manager/obsidian-sync.nix
  ];

  nelhage.jupyterlab.enable = true;
  nelhage.jupyterlab.extraConfig = ''
    c.ServerApp.allow_remote_access = True
    c.IdentityProvider.token = ""
    c.PasswordIdentityProvider.password_required = True
    c.PasswordIdentityProvider.hashed_password = 'argon2:$argon2id$v=19$m=10240,t=10,p=8$XwRENUHQXYJIGROZME3LMA$PCdjNQRKMSWv7ESG86tpAKn1xNsjRMDd5gkWk9to5dk'
  '';

  nelhage.garmindb.enable = true;
  nelhage.garmindb.litestream.enable = false;
  nelhage.garmindb.litestream.replicaRoot = "gcs://nelhage-data/garmin";
  nelhage.garmindb.parquet = {
    enable = true;
    gcsDestination = "gs://nelhage-data/garmin";
  };

  age.secrets."gcloud.json" = {
    file = ../../secrets/hw4-gcloud.json.age;
  };
  nelhage.gcloud.enable = true;
  nelhage.gcloud.project = "livegrep";

  age.secrets."aws-credentials" = {
    file = ../../secrets/hw4-aws-credentials.age;
  };
  nelhage.aws.enable = true;

  nelhage.obsidian-sync.enable = true;

  nelhage.dotfiles.symlink = true;
  nelhage.dotfiles.checkout_path = "/etc/nixos";
}

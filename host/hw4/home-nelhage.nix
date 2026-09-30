{ config, pkgs, ... }:
{
  imports = [
    ../../home-manager/litestream.nix
    ../../home-manager/jupyterlab.nix
    ../../home-manager/obsidian-sync.nix
  ];

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

  nelhage.claude-remote = {
    enable = true;
    projects =
      let
        project = dir: {
          directory = "${config.home.homeDirectory}/${dir}";
          sessionNamePrefix = "hw4:${baseNameOf dir}";
        };
      in
      {
        sandbox = project "code/sandbox";
        obsidian = project "Obsidian";
        nix-config = project "code/nix-config";
      };
  };

  nelhage.dotfiles.symlink = true;
  nelhage.dotfiles.checkout_path = "/etc/nixos";
}

{ config, pkgs, ... }:
{
  imports = [
    ../../home-manager/litestream.nix
    ../../home-manager/jupyterlab.nix
    ../../home-manager/obsidian-sync.nix
  ];

  nelhage.jupyterlab.enable = true;
  # Authentication is handled upstream: lab.nelhage.com is gated by oauth2-proxy
  # (Google login), and nginx injects an `Authorization: token ...` header on
  # that path from the `jupyter-auth` secret (see host/hw4/nixos.nix). We read
  # the token out of that same secret here so Jupyter requires it; direct
  # requests to 127.0.0.1:8002 without the header are rejected. The secret
  # holds an nginx directive line, so we pull the token out with a regex.
  nelhage.jupyterlab.extraConfig = ''
    import pathlib, re

    c.ServerApp.allow_remote_access = True
    c.IdentityProvider.token = re.search(
        r'token ([^"]+)"',
        pathlib.Path("/run/agenix/jupyter-auth").read_text(),
    ).group(1)
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

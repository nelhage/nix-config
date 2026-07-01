let
  keys = {
    "nelhage@mythique" =
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOj/9YTjI5Pr3TrzFMr9ADLTw7yeJZ6jCejXRL9N0rku";
    "nelhage@quintique" =
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFmPipxHnb2OmJVcROfX6HGkAwLD9SJqO5aJ5seRZtRT";
    "nelhage@hw4" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICWq0k8tVchAd1CvETrnD0JjUBRDivwhfdxJTwn4BYQh";
    hw4 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC2I7i0sAOdoECTR4rpyOP9VsVBSx3giBIVoQUlYg4UF";
    "nelhage@nomadique" =
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPykNiHYxVQ2nfR/erLMW+5bYvPCqzjG3KzoeDvWA/8E";

  };
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

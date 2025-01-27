let
  keys = {
    "nelhage@mythique" =
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOj/9YTjI5Pr3TrzFMr9ADLTw7yeJZ6jCejXRL9N0rku";
    "nelhage@hw4" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICWq0k8tVchAd1CvETrnD0JjUBRDivwhfdxJTwn4BYQh";
    hw4 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC2I7i0sAOdoECTR4rpyOP9VsVBSx3giBIVoQUlYg4UF";
  };
  me = [
    keys."nelhage@mythique"
    keys."nelhage@hw4"
  ];
  nelhage_com = [ keys.hw4 ];
in
{
  "hw4-gcloud.json.age".publicKeys = nelhage_com ++ me;
  "nelhage-services.age".publicKeys = nelhage_com ++ me;
  "gcp-service.json.age".publicKeys = nelhage_com ++ me;
  "garmin.password.age".publicKeys = nelhage_com ++ me;
}

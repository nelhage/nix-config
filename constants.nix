# Shared constants referenced across this flake: SSH public keys and hardcoded
# IP addresses. This file is a plain attrset (no arguments) so that it can be
# imported both by the flake (and passed down via `specialArgs`/
# `extraSpecialArgs`) and standalone by `secrets/secrets.nix`, which agenix
# evaluates outside of the flake.
{
  sshKeys = {
    "nelhage@mythique" =
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOj/9YTjI5Pr3TrzFMr9ADLTw7yeJZ6jCejXRL9N0rku nelhage@mythique";
    "nelhage@quintique" =
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFmPipxHnb2OmJVcROfX6HGkAwLD9SJqO5aJ5seRZtRT nelhage@quintique";
    "nelhage@nomadique" =
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPykNiHYxVQ2nfR/erLMW+5bYvPCqzjG3KzoeDvWA/8E nelhage@nomadique";
    "nelhage@hw4" =
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICWq0k8tVchAd1CvETrnD0JjUBRDivwhfdxJTwn4BYQh nelhage@hw4";
    "nelhage@pixel-ten" =
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILAc21zLDUk1y2VP2AIUtKhGT5SUrmPN0xI4nFn7bqmU nelhage@pixel-ten";
    "nelhage@anthropic-laptop" =
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBFzLlWzdMDU5vbNJNEneUfSoOtMz7xEzfVnfFTvLl/atHO8qKBn97IwmOZwnnxYhEOfnbHk0JB/mA083yQQ2w+M= nelhage@anthropic-laptop";

    # Host key for hw4 (nelhage.com).
    hw4 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC2I7i0sAOdoECTR4rpyOP9VsVBSx3giBIVoQUlYg4UF hw4";
  };

  ipAddresses = {
    # Tailscale address of hw4 (nelhage.com).
    hw4Tailscale = "100.78.93.125";
  };
}

{ pkgs, ... }:
{
  imports = [
    ./agenix.nix
  ];
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
}

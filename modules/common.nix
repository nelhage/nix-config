{ pkgs, ... }:
{
  nix.settings.experimental-features = [
    "nix-command"
    "repl-flake"
    "flakes"
  ];
}

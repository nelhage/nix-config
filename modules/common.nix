{ pkgs, lib, ... }:
{
  imports = [
    ./agenix.nix
  ];
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "aspell-dict-en-science"
      "aspell-dict-en-computer"
    ];
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
}

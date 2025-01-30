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
  nixpkgs.config.permittedInsecurePackages = [
    # https://github.com/benbjohnson/litestream/pull/609
    # I don't use `sftp` remotes.
    "litestream-0.3.13"
  ];
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.settings.trusted-users = [
    "nelhage"
  ];
}

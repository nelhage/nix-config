# Shared configuration imported by NixOS hosts, nix-darwin systems, and
# standalone home-manager configurations. Keep options here restricted to
# those accepted by all three module systems.
{ lib, ... }:
{
  imports = [ ];
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "aspell-dict-en-science"
      "aspell-dict-en-computer"
      "1password-cli"
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

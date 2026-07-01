{
  pkgs,
  config,
  ...
}:
let
  inherit (config.lib.file) mkOutOfStoreSymlink;
in
{
  home.packages = [ pkgs.reattach-to-user-namespace ];

  home.file = {
    tailscale = {
      target = "bin/tailscale";
      text = ''
        #!/usr/bin/env bash
        exec /Applications/Tailscale.app/Contents/MacOS/Tailscale "$@"
      '';
      executable = true;
    };

    nix-darwin = {
      target = ".config/nix-darwin";
      source = mkOutOfStoreSymlink "${config.home.homeDirectory}/code/nix-config";
    };
  };
}

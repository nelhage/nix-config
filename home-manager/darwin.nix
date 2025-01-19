{
  pkgs,
  ...
}:
{
  home.packages = [ pkgs.reattach-to-user-namespace ];

  dotfiles.symlink = true;

  home.file = {
    tailscale = {
      target = "bin/tailscale";
      text = ''
        #!/usr/bin/env bash
        exec /Applications/Tailscale.app/Contents/MacOS/Tailscale "$@"
      '';
      executable = true;
    };
  };
}

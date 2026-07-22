{
  pkgs,
  ...
}:
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
  };

  nelhage.local-caddy = {
    enable = true;
    gcpProject = "livegrep";
    sites = {
      "lab.nelhage.me" = 8002;
      "blog.nelhage.me" = 1313;
      "notebook.nelhage.me" = 1987;
      "syncthing.nelhage.me" = {
        port = 8384;
        # Syncthing's web UI refuses connections whose Host header isn't
        # localhost, so rewrite it on the way upstream.
        extraCaddyConfig = "header_up Host localhost";
      };
    };
  };

  nelhage.jupyterlab.extraConfig = ''
    c.ServerApp.allow_remote_access = True
    c.ServerApp.trust_xheaders = True
  '';
}

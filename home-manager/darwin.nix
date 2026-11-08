{
  pkgs,
  ...
}:
let
  inherit (pkgs) lib;
  inherit (lib.attrsets) genAttrs mapAttrs;
in
{
  imports = [
    ./iterm2.nix
  ];

  home.packages = [ pkgs.reattach-to-user-namespace ];

  home.file =
    let
      appWrappers = {
        tailscale = {
          application = "Tailscale.app";
          command = "Tailscale";
        };
        mw = {
          application = "MacWhisper.app";
          command = "mw";
        };
      }
      //
        genAttrs
          [
            "ebook-convert"
            "ebook-device"
            "ebook-edit"
            "ebook-meta"
            "ebook-polish"
            "ebook-viewer"

          ]
          (_: {
            application = "calibre.app";
          });
    in
    mapAttrs (
      name: config:
      let
        application = config.application;
        binary = config.command or name;
      in
      {
        target = "bin/${name}";
        text = ''
          #!/usr/bin/env bash
          exec /Applications/${application}/Contents/MacOS/${binary} "$@"
        '';
        executable = true;
      }
    ) appWrappers;

  nelhage.iterm2.enable = true;

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

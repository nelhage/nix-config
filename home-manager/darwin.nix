{
  pkgs,
  nixpkgs,
  config,
  ...
}:
{
  home.homeDirectory = "/Users/nelhage";

  nix.registry = {
    nixpkgs = {
      from = {
        type = "indirect";
        id = "nixpkgs";
      };
      to = {
        type = "path";
        path = nixpkgs.outPath;
      };
    };
  };

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

  launchd.agents =
    let
      logdir = "${config.home.homeDirectory}/Library/Logs/";
    in
    {
      "hugo-notes" = {
        enable = true;
        config = {
          Label = "com.nelhage.hugo-notes";

          ProgramArguments = [
            "${pkgs.hugo}/bin/hugo"
            "serve"
            "-D"
            "--port"
            "1987"
            "--disableFastRender"
            "--destination"
            "_preview"
          ];

          WorkingDirectory = "${config.home.homeDirectory}/code/writing";
          KeepAlive = true;
          RunAtLoad = true;

          StandardErrorPath = "${logdir}/hugo/notes-stdout.log";
          StandardOutPath = "${logdir}/hugo/notes-stderr.log";
        };
      };

      "hugo-blog" = {
        enable = true;
        config = {
          Label = "com.nelhage.hugo-blog";

          ProgramArguments = [
            "${pkgs.hugo}/bin/hugo"
            "serve"
            "-D"
            "-F"
            "cleanDestinationDir"
            "--disableFastRender"
            "--destination"
            "_preview"
          ];

          WorkingDirectory = "${config.home.homeDirectory}/code/blog.nelhage.com";
          KeepAlive = true;
          RunAtLoad = true;
          StandardErrorPath = "${logdir}/hugo/stdout.log";
          StandardOutPath = "${logdir}/hugo/stderr.log";
        };
      };
    };
}

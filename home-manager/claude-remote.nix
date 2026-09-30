{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) types mkOption;
  opts = config.nelhage.claude-remote;

  projectOpts =
    { name, ... }:
    {
      options = {
        directory = mkOption {
          type = types.str;
          description = "Directory in which to run `claude remote-control`.";
        };

        name = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Session title shown at claude.ai/code (`--name`).";
        };

        sessionNamePrefix = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Prefix for auto-generated session names (`--remote-control-session-name-prefix`). Defaults to the hostname.";
        };

        spawn = mkOption {
          type = types.nullOr (
            types.enum [
              "same-dir"
              "worktree"
              "session"
            ]
          );
          default = null;
          description = "How the server creates sessions (`--spawn`).";
        };

        capacity = mkOption {
          type = types.nullOr types.ints.positive;
          default = null;
          description = "Maximum number of concurrent sessions (`--capacity`).";
        };

        createSessionInDir = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = "Pre-create a session in the directory on startup (`--[no-]create-session-in-dir`). null uses Claude's default (on).";
        };

        permissionMode = mkOption {
          type = types.nullOr (
            types.enum [
              "default"
              "manual"
              "acceptEdits"
              "auto"
              "bypassPermissions"
              "dontAsk"
              "plan"
            ]
          );
          default = null;
          description = "Starting permission mode for the server's sessions (`--permission-mode`).";
        };

        chrome = mkOption {
          type = types.nullOr types.bool;
          default = null;
          description = "Enable Claude in Chrome for spawned sessions (`--[no-]chrome`). null uses Claude's default.";
        };

        debug = mkOption {
          type = types.either types.bool types.str;
          default = false;
          description = "Enable debug logging (`--debug`). A string is used as a category filter, e.g. \"api,hooks\".";
        };

        debugFile = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Write debug logs to this file (`--debug-file`).";
        };

        verbose = mkOption {
          type = types.bool;
          default = false;
          description = "Show detailed connection and session logs (`--verbose`).";
        };

        extraArgs = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Additional arguments to pass to `claude remote-control`.";
        };
      };
    };

  unitName = name: "claude-remote-${name}";

  mkArgs =
    p:
    let
      optArg = flag: v: lib.optionals (v != null) [ "${flag}=${toString v}" ];
      boolArg = flag: v: lib.optional (v != null) (if v then "--${flag}" else "--no-${flag}");
    in
    [
      "claude"
      "remote-control"
    ]
    ++ optArg "--name" p.name
    ++ optArg "--remote-control-session-name-prefix" p.sessionNamePrefix
    ++ optArg "--spawn" p.spawn
    ++ optArg "--capacity" p.capacity
    ++ boolArg "create-session-in-dir" p.createSessionInDir
    ++ optArg "--permission-mode" p.permissionMode
    ++ boolArg "chrome" p.chrome
    ++ (
      if p.debug == true then
        [ "--debug" ]
      else if builtins.isString p.debug then
        [ "--debug=${p.debug}" ]
      else
        [ ]
    )
    ++ optArg "--debug-file" p.debugFile
    ++ lib.optional p.verbose "--verbose"
    ++ p.extraArgs;

  mkService = name: p: {
    Unit = {
      Description = "claude remote-control for ${name}";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      WorkingDirectory = p.directory;
      # Run under an interactive zsh so claude picks up the normal shell environment.
      ExecStart = pkgs.writeShellScript (unitName name) ''
        exec ${
          lib.escapeShellArgs [
            opts.shell
            "-i"
            "-c"
            "exec ${lib.escapeShellArgs (mkArgs p)}"
          ]
        }
      '';
      Restart = "always";
      RestartSec = 10;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
in
{
  options.nelhage.claude-remote = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Run `claude remote-control` servers as systemd user services";
    };

    shell = mkOption {
      type = types.str;
      default = "${pkgs.zsh}/bin/zsh";
      description = "Shell used (interactively) to launch claude";
    };

    projects = mkOption {
      type = types.attrsOf (types.submodule projectOpts);
      default = { };
      description = "Projects to run `claude remote-control` in, keyed by name";
    };
  };

  config = lib.mkIf opts.enable {
    assertions = lib.mapAttrsToList (name: p: {
      assertion = !(p.spawn == "session" && p.capacity != null);
      message = "nelhage.claude-remote.projects.${name}: `capacity` can't be used with `spawn = \"session\"`";
    }) opts.projects;

    systemd.user.services = lib.mapAttrs' (
      name: p: lib.nameValuePair (unitName name) (mkService name p)
    ) opts.projects;
  };
}

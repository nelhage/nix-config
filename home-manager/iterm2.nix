{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nelhage.iterm2;

  mkDynamicProfile = pkgs.callPackage ../pkgs/base16-iterm2.nix {
    inherit (pkgs.nelhage) base16-shell;
  };
in
{
  options.nelhage.iterm2 = {
    enable = lib.mkEnableOption "baking the base16 colorscheme into iTerm2";

    theme = lib.mkOption {
      type = lib.types.str;
      default = "isotope";
      description = ''
        base16-shell theme to bake into the iTerm2 profile. Should match
        whatever `base16-*` script the shell runs at startup.
      '';
    };

    parentProfile = lib.mkOption {
      type = lib.types.str;
      default = "Default";
      description = ''
        Name of the iTerm2 profile to inherit non-color settings (font,
        keybindings, ...) from. That profile stays editable in the GUI.
      '';
    };

    guid = lib.mkOption {
      type = lib.types.str;
      default = "F1417E56-7AE6-4901-911E-EAAA61B63FBD";
      description = "GUID for the generated profile. Arbitrary, but must be stable.";
    };

    setDefault = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Make the generated profile iTerm2's default. Only takes effect if
        iTerm2 isn't running at activation time, since it rewrites its
        preferences on quit.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.file."Library/Application Support/iTerm2/DynamicProfiles/base16.json".source =
      mkDynamicProfile
        {
          inherit (cfg) theme guid;
          parentName = cfg.parentProfile;
        };

    targets.darwin.defaults."com.googlecode.iterm2" = lib.mkIf cfg.setDefault {
      "Default Bookmark Guid" = cfg.guid;
    };
  };
}

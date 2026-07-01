{ config, lib, ... }:
{
  options =
    let
      inherit (lib) types;
    in
    {
      nelhage.dotfiles = {
        symlink = lib.mkOption {
          type = types.bool;
          default = false;
          description = "Whether to symlink dotfiles into a nix-config checkout";
        };

        checkout_path = lib.mkOption {
          type = types.str;
          default = "${config.home.homeDirectory}/code/nix-config";
          defaultText = "~/code/nix-config/";
          description = "Path to the nix-config checkout if nelhage.dotfiles.symlink=true";
        };

        syncthingDotfiles = lib.mkOption {
          type = types.listOf types.str;
          default = [
            "aspell.en.prepl"
            "aspell.en.pws"
            "claude/settings.json"
          ];
          description = ''
            List of dotfiles to symlink into ~/Sync/config.

            Entries should be relative paths relative to ~/, with no leading `.`.
          '';
        };
      };
    };

  config =
    let
      inherit (builtins) substring stringLength listToAttrs;
      inherit (config.lib.file) mkOutOfStoreSymlink;

      cfg = config.nelhage.dotfiles;

      fs = lib.filesystem;
      root = ./dotfiles;
      toRelative = path: substring (1 + stringLength (toString root)) (-1) (toString path);
      fileList = fs.listFilesRecursive root;
      verbatimDotfiles = listToAttrs (
        map (
          path:
          let
            rel = toRelative path;
          in
          {
            name = rel;
            value = {
              source =
                if cfg.symlink then
                  mkOutOfStoreSymlink "${cfg.checkout_path}/home-manager/dotfiles/${rel}"
                else
                  path;
              target = "." + rel;
            };
          }
        ) fileList
      );
      syncthingDotfiles = listToAttrs (
        map (name: {
          name = name;
          value = {
            source = mkOutOfStoreSymlink "${config.home.homeDirectory}/Sync/config/${name}";
            target = "." + name;
          };
        }) cfg.syncthingDotfiles
      );
    in
    {
      home.file = verbatimDotfiles // syncthingDotfiles;
    };
}

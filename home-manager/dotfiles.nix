{ config, lib, ... }:
{
  options =
    let
      inherit (lib) types;
    in
    {
      dotfiles = {
        symlink = lib.mkOption {
          type = types.bool;
          default = false;
          description = "Whether to symlink dotfiles into a nix-config checkout";
        };

        checkout_path = lib.mkOption {
          type = types.str;
          default = "${config.home.homeDirectory}/code/nix-config";
          defaultText = "~/code/nix-config/";
          description = "Path to the nix-config checkout if dotfiles.symlink=true";
        };
      };
    };

  config =
    let
      inherit (builtins) substring stringLength listToAttrs;
      fs = lib.filesystem;
      root = ./dotfiles;
      toRelative = path: substring (1 + stringLength (toString root)) (-1) (toString path);
      fileList = fs.listFilesRecursive root;
    in
    {
      home.file = listToAttrs (
        map (
          path:
          let
            rel = toRelative path;
          in
          {
            name = rel;
            value = {
              source =
                if config.dotfiles.symlink then
                  config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.checkout_path}/home-manager/dotfiles/${rel}"
                else
                  path;
              target = "." + rel;
            };
          }
        ) fileList
      );
    };
}

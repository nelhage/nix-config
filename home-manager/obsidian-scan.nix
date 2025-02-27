{ pkgs, ... }:
{
  home.packages = [ pkgs.nelhage.obsidian-scan ];
  home.file = {
    obsidian-scan = {
      target = ".emacs.d/home-manager";
      source = pkgs.nelhage.obsidian-scan.elisp;
      recursive = true;
    };
  };
}

{ pkgs, ... }:
{
  home.packages = [ pkgs.obsidian-scan ];
  home.file = {
    obsidian-scan = {
      target = ".emacs.d/home-manager";
      source = pkgs.obsidian-scan.elisp;
      recursive = true;
    };
  };
}

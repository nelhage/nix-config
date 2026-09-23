{ pkgs, ... }:
{
  home.packages = [
    pkgs.nelhage.obsidian-scan
  ];
  home.file =
    let
      elispPackage =
        pkgs.runCommand "home-manager-elisp"
          {
          }
          ''
            mkdir $out
            ln -nsf ${pkgs.nelhage.obsidian-scan.elisp}/* "$out";
          '';
    in
    {
      obsidian-scan = {
        target = ".emacs.d/home-manager";
        source = elispPackage;
        recursive = true;
      };
    };
}

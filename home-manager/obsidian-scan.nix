{ pkgs, ... }:
{
  home.packages = [
    pkgs.nelhage.obsidian-scan
  ];
  home.file =
    let
      obsidianFork = pkgs.fetchFromGitHub {
        owner = "nelhage";
        repo = "obsidian.el";
        rev = "7804cba1d990cc90bd93af69941a6b6cd5f599bc";
        hash = "sha256-ojIuSAfLy64TDzMFDDIKhtPG/RdU7Pk28UrQjaVubrg";
      };
      elispPackage =
        pkgs.runCommand "home-manager-elisp"
          {
          }
          ''
            mkdir $out
            ln -nsf ${pkgs.nelhage.obsidian-scan.elisp}/* "$out";
            ln -nsf ${obsidianFork}/obsidian.el "$out";
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

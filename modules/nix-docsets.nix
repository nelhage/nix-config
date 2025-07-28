{ pkgs, ... }:
{
  system.activationScripts.symlinkDocsets =
    let
      docsetFeed = pkgs.nelhage.mkNixDocsetFeed {
        baseURL = "https://nelhage.com/nix-docsets";
      };
    in
    {
      text = ''
        ln -nsf ${docsetFeed} /data/www/nelhage.com/nix-docsets
      '';
    };
}

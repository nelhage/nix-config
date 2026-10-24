{ lib, pkgs, ... }:
let
  brotliFixed = pkgs.brotli.overrideAttrs (old: {
    version = "1.2.1";
    src = pkgs.fetchFromGitHub {
      owner = "google";
      repo = "brotli";
      tag = "v1.2.1";
      hash = "sha256-llY72cYffDv0ugsH0p89xIPEbElV4L8u7U/Fe8hT3gI=";
    };
  });
in
{
  # brotli < 1.2.1 has an out-of-bounds write in the decoder
  # (AIKIDO-2026-100918). The fix is stuck in staging, and brotli is too far
  # down the dependency graph to override cheaply, so graft a fixed build into
  # the system closure instead. Throws once nixpkgs' brotli is fixed, so this
  # can't silently outlive its usefulness.
  system.replaceDependencies.replacements =
    if lib.versionAtLeast pkgs.brotli.version "1.2.1" then
      throw ''
        nixpkgs' `brotli` is now version ${pkgs.brotli.version}, which fixes
        AIKIDO-2026-100918: remove modules/brotli.nix and its import from
        modules/nixos.nix.
      ''
    else
      map
        (output: {
          oldDependency = pkgs.brotli.${output};
          newDependency = brotliFixed.${output};
        })
        [
          "out"
          "lib"
        ];
}

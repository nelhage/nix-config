{ callPackage, python3, ... }:
callPackage ../../lib/build-uv-package.nix {
  name = "garmin";
  version = "0.1.0";
  src = ./.;

  packagesHash = {
    x86_64-linux = "sha256-tLyTkb0jvi1GM+XWVDObid0r+eTOT3uDPHTbQtJhHlc=";
    aarch64-darwin = "sha256-u8Xq0IR9O56rkJivtUK/GeAnyyMcPVPWnN0OOj64Cws=";
  };
  useUvPip = true;

  inherit python3;
}

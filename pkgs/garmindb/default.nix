{ callPackage, python3, ... }:
callPackage ../../lib/build-uv-package.nix {
  name = "garmin";
  version = "0.1.0";
  src = ./.;

  packagesHash = {
    x86_64-linux = "sha256-w1/4UmHic3sVlcX/WPwWcPVuP6b6cfDGXpBEd5okYTo=";
    aarch64-darwin = "sha256-Lrz5/5ZAhUjsdXLSJBNz12MRUKIOt90EaPWuXNnHw5Y=";
  };

  inherit python3;
}

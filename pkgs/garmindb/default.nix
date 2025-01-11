{callPackage, python3, ...}:
callPackage ../../lib/build-uv-package.nix {
  name = "garmin";
  version = "0.1.0";
  src = ./.;

  packagesHash = {
    aarch64-darwin = "sha256-Lrz5/5ZAhUjsdXLSJBNz12MRUKIOt90EaPWuXNnHw5Y=";
  };

  inherit python3;
}

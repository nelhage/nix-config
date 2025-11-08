{ callPackage, python3, ... }:
callPackage ../../lib/build-uv-package.nix {
  name = "garmin";
  version = "0.1.0";
  src = ./.;

  packagesHash = {
    x86_64-linux = "sha256-3OYbyp9n2NJJn5eUsBZV+RA0cwbx1nGyIdU5/j8+n/w=";
    aarch64-darwin = "sha256-/dIN7q4JfnBU/cr1iAPUyfm0Pn6b2eJCA/1m4QQMLvY=";
  };
  useUvPip = true;

  inherit python3;
}

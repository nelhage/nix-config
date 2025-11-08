{ callPackage, python3, ... }:
callPackage ../../lib/build-uv-package.nix {
  name = "jupyterlab-env";
  version = "0.1.0";
  src = ./.;

  packagesHash = {
    x86_64-linux = "sha256-I83+jLvyZbjBW3hTuhAHry+k4j+4UFVEpiIyZ0USQDM=";
    aarch64-darwin = "sha256-NQmo/BDlF2ODf6cBq8DiH/c+pwn2kAMOQ4/eoqYTv2M=";
  };
  useUvPip = true;

  inherit python3;
}

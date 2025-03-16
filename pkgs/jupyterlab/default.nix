{ callPackage, python3, ... }:
callPackage ../../lib/build-uv-package.nix {
  name = "jupyterlab-env";
  version = "0.1.0";
  src = ./.;

  packagesHash = {
    x86_64-linux = "sha256-C9Uy7AofwO2QYOKRXLMl2fDeIKOD4gKUps1EVCSk0Ts=";
    aarch64-darwin = "sha256-oaz4yhJJJLDwMwTVr8PX7gIw/Pl2Aq6lr8il3gKZOVY=";
  };
  useUvPip = true;

  inherit python3;
}

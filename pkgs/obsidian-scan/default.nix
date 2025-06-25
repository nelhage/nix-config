{
  lib,
  rustPlatform,
  stdenv,
  ...
}:
let
  fs = lib.fileset;
in
rustPlatform.buildRustPackage {
  pname = "obsidian-scan";
  version = "0.1.0";
  src = fs.toSource {
    root = ./.;
    fileset = (
      fs.unions [
        ./Cargo.lock
        ./Cargo.toml
        ./src
      ]
    );
  };

  cargoHash = "sha256-zd7uJvMQCrAv+g6euPhDQ2PD/nG5VnemOYETcGFnpU8=";

  passthru = {
    elisp = stdenv.mkDerivation {
      pname = "obsidian-scan";
      version = "0.1.0";
      src = ./emacs;
      installPhase = ''
        install -d $out
        install *.el $out/
      '';
    };
  };
}

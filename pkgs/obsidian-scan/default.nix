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

  cargoHash = "sha256-c8IJp60FBMOEjKyu9/MfhIhWQ1gA7bzobxcIW3PokBo=";

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

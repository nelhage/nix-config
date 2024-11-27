{
  lib,
  fetchFromGitHub,
  stdenv,
  ...
}:
stdenv.mkDerivation rec {
  pname = "base16-shell";
  version = "0.0.1";
  src = fetchFromGitHub {
    owner = "chriskempson";
    repo = "base16-shell";
    rev = "588691ba71b47e75793ed9edfcfaa058326a6f41";
    hash = "sha256-X89FsG9QICDw3jZvOCB/KsPBVOLUeE7xN3VCtf0DD3E";
  };

  buildPhase = ''
    mkdir -p $out/bin/
    for f in ./scripts/*.sh; do
      install -m 0755 "$f" "$out/bin/$(basename "''${f%.sh}")"
    done
  '';
}

{
  rustPlatform,
  fetchFromGitHub,
  lib,
  ...
}:
rustPlatform.buildRustPackage {
  pname = "stitch";
  version = "0.1.0-unstable-2026-11-14";

  src = fetchFromGitHub {
    owner = "nelhage";
    repo = "stitch";
    rev = "ac8c552661b484a3c6993baa6d3f0659cc916e4d";
    hash = "sha256-naHg9KNUb3KLnvgYzuzCovfDciCNZpLBgx0jowcVcy4=";
  };

  cargoHash = "sha256-KvMbWMHBwFs+YDIxSa3nGCNmWbvb3Yy2JfhDkQhhIyc=";

  meta = {
    description = "Reliable ssh connections";
    homepage = "https://github.com/nelhage/stitch";
    mainProgram = "stitch";
    platforms = lib.platforms.unix;
  };
}

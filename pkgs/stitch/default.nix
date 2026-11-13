{
  rustPlatform,
  fetchFromGitHub,
  lib,
  ...
}:
rustPlatform.buildRustPackage {
  pname = "stitch";
  version = "0.1.0-unstable-2026-11-12";

  src = fetchFromGitHub {
    owner = "nelhage";
    repo = "stitch";
    rev = "d60620960d129d8c4545802870f1e0e0cd0cc0b6";
    hash = "sha256-n4wmaL/StTWXjdMaFQ8IpVPUwtuaqVpKVhv+jDKbiKw=";
  };

  cargoHash = "sha256-KvMbWMHBwFs+YDIxSa3nGCNmWbvb3Yy2JfhDkQhhIyc=";

  meta = {
    description = "Reliable ssh connections";
    homepage = "https://github.com/nelhage/stitch";
    mainProgram = "stitch";
    platforms = lib.platforms.unix;
  };
}

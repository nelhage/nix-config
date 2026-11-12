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
    rev = "1dd2c351b28d18025022eb375482e0160effba19";
    hash = "sha256-0ucq3VpLSpubkk9r3/8WPNEZXnifGX3bMX5SiGpzrrs=";
  };

  cargoHash = "sha256-KvMbWMHBwFs+YDIxSa3nGCNmWbvb3Yy2JfhDkQhhIyc=";

  meta = {
    description = "Reliable ssh connections";
    homepage = "https://github.com/nelhage/stitch";
    mainProgram = "stitch";
    platforms = lib.platforms.unix;
  };
}

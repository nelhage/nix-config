{
  rustPlatform,
  fetchFromGitHub,
  ...
}:
rustPlatform.buildRustPackage {
  pname = "syncflowy";
  version = "0.1.0-unstable-2026-10-15";

  src = fetchFromGitHub {
    owner = "nelhage";
    repo = "syncflowy";
    rev = "f29e4f9c92b9a2cc58a03856712efc4aef3151a9";
    hash = "sha256-GufCUTRHOhXELlKmGo3CoXX/vR4vw/cEculpQXBziJU=";
  };

  # The Rust engine lives in a subdirectory; the Python half of the repo is the
  # mock server and conformance tooling, which the daemon doesn't need.
  sourceRoot = "source/engine";

  cargoHash = "sha256-CW0wZOkCj4iux5OL7H5/Fi6xj6CGF7imONRK3QtjFg4=";

  # The end-to-end tests spawn the Python mock server via `uv run`.
  doCheck = false;

  meta.mainProgram = "syncflowy";
}

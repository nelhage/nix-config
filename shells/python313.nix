{
  mkShell,
  python313,
  uv,
}:
mkShell {
  packages = [
    python313
    uv
  ];
}

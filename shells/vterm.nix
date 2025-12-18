{
  mkShell,
  gnumake,
  libvterm,
  libtool,
  perl,
}:
mkShell {
  packages = [
    gnumake
    perl
  ];
  buildInputs = [
    libtool
  ];
}

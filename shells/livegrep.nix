{
  mkShell,
  bazel_7,
  llvmPackages_20,
}:
(mkShell.override { stdenv = llvmPackages_20.stdenv; }) {
  packages = [
    bazel_7
    llvmPackages_20.clang
  ];
}

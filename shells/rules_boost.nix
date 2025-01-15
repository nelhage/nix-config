{
  mkShell,
  bazel_7,
  # llvmPackages,
  gcc14,
}:
mkShell {
  packages = [
    bazel_7
    gcc14
    # llvmPackages.libcxxClang
  ];
  shellHook = ''
    # Git on macos misbehaves when this is set.
    unset DEVELOPER_DIR
  '';
}

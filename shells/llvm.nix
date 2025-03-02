{
  mkShell,
  llvmPackages_19,
}:
let
  llvm = llvmPackages_19;
  pkgs = llvm.llvm.buildInputs ++ llvm.llvm.nativeBuildInputs;
in
mkShell {
  packages = pkgs ++ [ llvm.bintools ];
  hardeningDisable = [ "fortify" ];
}

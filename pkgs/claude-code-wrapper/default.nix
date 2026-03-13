{
  pkgs,
  stdenv,
  patchelf,
  ...
}:
let
  libc = stdenv.cc.libc;
in
pkgs.writeShellScriptBin "claude" ''
  set -eu

  claude_bin=/home/nelhage/.local/bin/claude

  if ! [ -x "$claude_bin" ]; then
      echo "No 'claude' binary found!" >&2
      exit 1
  fi

  interp="$(${patchelf}/bin/patchelf --print-interpreter "$claude_bin")"
  case "$interp" in
      /lib*)
          echo "Patching $claude_bin -> $(readlink "$claude_bin")"
          ld_linux="${libc}/lib/ld-linux-x86-64.so.2"
          ${patchelf}/bin/patchelf --set-interpreter "$ld_linux" "$claude_bin"
       ;;
  esac

  exec "$claude_bin" "$@"
''

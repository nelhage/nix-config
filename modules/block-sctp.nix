# Refuse to load the SCTP kernel module.
#
# The "nginx2root" writeup describes a use-after-free in the kernel's SCTP
# send path (present since Linux 4.15, no CVE assigned at time of writing)
# that turns code execution as an unprivileged user -- including inside a
# Docker container -- into root on the host:
#
#   https://xint.io/blog/nginx2root-remote-code-execution
#
# sctp.ko is otherwise autoloaded the first time anything opens an
# IPPROTO_SCTP socket. Nothing on these machines uses SCTP, so this is cheap
# to keep even after the kernel is fixed; there is no fixed version to guard
# on yet. To remove: delete this file and its import in modules/nixos.nix.
{ pkgs, ... }:
{
  boot.extraModprobeConfig = ''
    install sctp ${pkgs.coreutils}/bin/false
  '';
}

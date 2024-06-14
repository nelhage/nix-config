{ config, pkgs, ... }:
{
  home.packages = [
    (
      let
        tailscale = pkgs.tailscale;
      in
      pkgs.stdenv.mkDerivation {
        name = "tailscale-completion-zsh-${tailscale.version}";
        src = tailscale;
        buildInputs = [ tailscale ];
        buildPhase = "tailscale completion zsh > _tailscale";
        installPhase = "mkdir -p $out/share/zsh/site-functions; install -t $out/share/zsh/site-functions _tailscale";
      }
    )
  ];
}

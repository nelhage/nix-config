{ inputs, config, ... }:
{
  imports = [ inputs.agenix.nixosModules.default ];
  home-manager = {
    sharedModules = [
      inputs.agenix.homeManagerModules.default
      (
        let
          users = config.users.users;
        in
        { config, pkgs, ... }:
        let
          uid = users.${config.home.username}.uid;
          # /run/user/$uid is the Linux XDG_RUNTIME_DIR tmpfs; it doesn't exist
          # on macOS (and can't be created by an unprivileged user), so fall back
          # to a stable, user-writable path there.
          runDir =
            if pkgs.stdenv.hostPlatform.isDarwin then
              "${config.home.homeDirectory}/Library/Caches/agenix"
            else
              "/run/user/${builtins.toString uid}";
        in
        {
          age.secretsDir = "${runDir}/agenix";
          age.secretsMountPoint = "${runDir}/agenix.d";
        }
      )
    ];
  };
}

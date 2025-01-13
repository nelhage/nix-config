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
        { config, ... }:
        let
          uid = users.${config.home.username}.uid;
          runDir = "/run/user/${builtins.toString uid}";
        in
        {
          age.secretsDir = "${runDir}/agenix";
          age.secretsMountPoint = "${runDir}/agenix.d";
        }
      )
    ];
  };
}

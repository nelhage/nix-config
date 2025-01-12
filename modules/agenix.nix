{ inputs, ... }:
{
  imports = [ inputs.agenix.nixosModules.default ];
  home-manager = {
    sharedModules = [ inputs.agenix.homeManagerModules.default ];
  };
}

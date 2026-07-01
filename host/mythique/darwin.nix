{ constants, ... }:
{
  imports = [
    ../../darwin/common.nix
    ../../darwin/home-manager.nix
  ];

  services.openssh = {
    enable = true;
    extraConfig = ''
      AuthenticationMethods publickey
      AllowUsers nelhage
    '';
  };

  users.users.nelhage.openssh.authorizedKeys.keys = [
    constants.sshKeys."nelhage@pixel-ten"
    constants.sshKeys."nelhage@quintique"
  ];

  home-manager.users.nelhage = import ./home-nelhage.nix;
}

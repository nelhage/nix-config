{ pkgs, constants, ... }:
{
  virtualisation.vmVariant.virtualisation = {
    sharedDirectories = {
      nix-config = {
        source = "/Users/nelhage/.android/avd";
        target = "/mnt/avd";
      };
    };

    forwardPorts = [
      {
        from = "host";
        guest.port = 22;
        host.port = 33322;
      }
    ];
  };

  environment.defaultPackages = with pkgs; [
    file
    qemu
    unixtools.xxd
  ];

  users.users.nelhage = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      constants.sshKeys."nelhage@mythique"
    ];
  };

  services.openssh.enable = true;
}

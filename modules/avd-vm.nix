{pkgs, ...}: {
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
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOj/9YTjI5Pr3TrzFMr9ADLTw7yeJZ6jCejXRL9N0rku nelhage@mythique"
    ];
  };

  services.openssh.enable = true;
}

{pkgs, ...}: {
  virtualisation.vmVariant.virtualisation = {
    sharedDirectories = {
      nix-config = {
        source = "/Users/nelhage/.android/avd";
        target = "/mnt/avd";
      };
    };
  };

  environment.defaultPackages = with pkgs; [
    file
    qemu
  ];
}

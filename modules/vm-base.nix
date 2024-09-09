{pkgs, ...}: {
  imports = [
    ../modules/common.nix
  ];

  system.stateVersion = "22.05";

  # Configure networking
  networking.useDHCP = false;
  networking.interfaces.eth0.useDHCP = true;

  services.getty.autologinUser = "nelhage";
  users.users.nelhage.isNormalUser = true;

  users.users.nelhage.extraGroups = ["wheel"];
  security.sudo.wheelNeedsPassword = false;
}

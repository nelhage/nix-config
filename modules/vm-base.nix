{ pkgs, lib, ... }:
{
  imports = [
    ../modules/common.nix
  ];

  system.stateVersion = "22.05";

  # This dance lets `nix flake check` be happy with the base
  # configuration, but still make us be bootable inside a VM.
  boot.loader.grub.enable = false;
  boot.initrd.enable = false;

  virtualisation.vmVariant = {
    boot = lib.mkVMOverride {
      loader.grub.enable = true;
      initrd.enable = true;
    };
  };

  # Configure networking
  networking.useDHCP = false;
  networking.interfaces.eth0.useDHCP = true;

  services.getty.autologinUser = "nelhage";
  users.users.nelhage.isNormalUser = true;

  users.users.nelhage.extraGroups = [ "wheel" ];
  security.sudo.wheelNeedsPassword = false;
}

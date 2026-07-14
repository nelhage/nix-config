{ pkgs, lib, ... }:
{
  imports = [
    ../modules/common.nix
    ../modules/agenix.nix
    ./homebrew.nix
  ];

  environment.systemPackages = [
    pkgs.coreutils-prefixed
  ];

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true; # default shell on catalina
  # programs.fish.enable = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  users.users.nelhage = {
    uid = 501;
    gid = 20;
    home = "/Users/nelhage";
    isHidden = false;
    description = "Nelson Elhage";
  };

  environment.etc."sudoers.d/01-nelhage" = {
    text = ''
      nelhage   ALL=(ALL:ALL) NOPASSWD: ALL
    '';
  };

  system.activationScripts.postActivation.text = ''
    ln -nsf /Users/nelhage/code/nix-config/ /etc/nix-darwin
  '';

  fonts.packages = [ pkgs.nerd-fonts.fira-code ];
  nix.optimise.automatic = true;

  system = {
    primaryUser = "nelhage";

    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToControl = true;
    };

    defaults = {
      dock = {
        autohide = true;
        orientation = "right";
        appswitcher-all-displays = true;
      };
      finder = {
        ShowPathbar = true;
        FXPreferredViewStyle = "clmv";
      };

      NSGlobalDomain = {
        KeyRepeat = 2;
        InitialKeyRepeat = 15;
      };

      menuExtraClock.Show24Hour = true;
    };
  };
}

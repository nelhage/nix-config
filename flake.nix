{
  description = "Nelson Elhage's combined Nix configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, disko, ... }: {
    homeConfigurations."nelhage@mythique" = let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
    in home-manager.lib.homeManagerConfiguration {
      inherit pkgs;

      modules = [ ./home.nix ];
    };

    nixosConfigurations.hw4 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        disko.nixosModules.disko
        ./hw4.nelhage.com/configuration.nix
        ./hw4.nelhage.com/hardware-configuration.nix
      ];
    };
  };
}

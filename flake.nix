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

  outputs =
    {
      nixpkgs,
      home-manager,
      disko,
      ...
    }@attrs:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-linux"
        "x86_64-linux"
        "aarch64-darwin"
      ];
    in
    {
      homeConfigurations."nelhage@mythique" =
        let
          system = "aarch64-darwin";
          pkgs = nixpkgs.legacyPackages.${system};
        in
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            nixpkgs = nixpkgs;
          };

          modules = [
            ./home-manager/home.nix
            ./home-manager/laptop.nix
            ./home-manager/darwin.nix
          ];
        };

      nixosConfigurations.hw4 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit home-manager;
        };
        modules = [
          disko.nixosModules.disko
          ./modules/nelhage.com.nix
          ./modules/common.nix
          ./hw4.nelhage.com/configuration.nix
          ./hw4.nelhage.com/hardware-configuration.nix
        ];
      };

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);

      templates.default = {
        path = ./template;
        description = "Development template";
        welcomeText = "Add your packages to flake.nix";
      };
    };
}

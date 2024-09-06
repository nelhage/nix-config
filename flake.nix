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

    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nix-darwin,
      disko,
      ...
    }@attrs:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-linux"
        "x86_64-linux"
        "aarch64-darwin"
      ];
      darwinRevisionConfig = {
        system.configurationRevision = self.rev or self.dirtyRev or null;
      };
      nixRegistryConfig = {
        nix.registry = {
          nixpkgs = {
            from = {
              type = "indirect";
              id = "nixpkgs";
            };
            to = {
              type = "path";
              path = nixpkgs.outPath;
            };
          };
        };
      };
    in
    {
      darwinConfigurations."mythique" = nix-darwin.lib.darwinSystem {
        specialArgs = {
          inherit home-manager;
        };
        modules = [
          ./darwin/common.nix
          ./darwin/home-manager.nix
          darwinRevisionConfig
          nixRegistryConfig
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

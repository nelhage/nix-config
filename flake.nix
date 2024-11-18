{
  description = "Nelson Elhage's combined Nix configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nix-darwin,
      disko,
      agenix,
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
      obsidian-scan = import ./src/obsidian-scan attrs;
      overlays = [
        agenix.overlays.default
        obsidian-scan.overlays.obsidian-scan
      ];
      overlayConfig = {
        nixpkgs.overlays = overlays;
      };
      lib = nixpkgs.lib;
    in
    lib.attrsets.recursiveUpdate {
      darwinConfigurations."mythique" = nix-darwin.lib.darwinSystem {
        specialArgs = {
          inherit home-manager nixpkgs;
        };
        modules = [
          overlayConfig
          agenix.darwinModules.default
          ./darwin/common.nix
          ./darwin/home-manager.nix
          ./modules/pin-nixpkgs.nix
          darwinRevisionConfig
        ];
      };

      nixosConfigurations.hw4 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit home-manager nixpkgs;
        };
        modules = [
          overlayConfig
          disko.nixosModules.disko
          agenix.nixosModules.default
          ./modules/nelhage.com.nix
          ./modules/common.nix
          ./hw4.nelhage.com/configuration.nix
          ./hw4.nelhage.com/hardware-configuration.nix
        ];
      };

      nixosConfigurations.avdVM = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = {
          inherit nixpkgs;
        };
        modules = [
          ./modules/vm-base.nix
          ./modules/darwin-vm.nix
          ./modules/avd-vm.nix
        ];
      };

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);

      templates.default = {
        path = ./template;
        description = "Development template";
        welcomeText = "Add your packages to flake.nix";
      };
    } obsidian-scan;
}

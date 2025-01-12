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
    agenix.inputs.home-manager.follows = "home-manager";
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
      lib = nixpkgs.lib;
    in
    lib.attrsets.recursiveUpdate rec {
      darwinConfigurations."mythique" = nix-darwin.lib.darwinSystem {
        specialArgs = {
          inherit home-manager nixpkgs;
        };
        modules = [
          nixosModules.overlays
          agenix.darwinModules.default
          ./darwin/mythique.nix
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
          nixosModules.overlays
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

      nixosModules.overlays = {
        nixpkgs.overlays = [
          agenix.overlays.default
          overlays.default
          obsidian-scan.overlays.obsidian-scan
        ];
      };

      overlays.default = final: prev: {
        base16-shell = packages.${prev.system}.base16-shell;
      };

      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          base16-shell = pkgs.callPackage ./pkgs/base16-shell.nix { };
          garmindb = pkgs.callPackage ./pkgs/garmindb { python = pkgs.python312; };
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          rules_boost = pkgs.callPackage ./shells/rules_boost.nix { };
        }
      );

      templates.default = {
        path = ./template;
        description = "Development template";
        welcomeText = "Add your packages to flake.nix";
      };
    } obsidian-scan;
}

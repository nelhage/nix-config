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
    }@inputs:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-linux"
        "x86_64-linux"
        "aarch64-darwin"
      ];
      subdirs = [
        ./src/obsidian-scan
      ];
      darwinRevisionConfig = {
        system.configurationRevision = self.rev or self.dirtyRev or null;
      };
      darwinVMHost = {
        virtualisation.vmVariant.virtualisation = {
          graphics = false;
          host.pkgs = nixpkgs.legacyPackages.aarch64-darwin;
        };
      };
      specialArgs = {
        inherit inputs;
      };
      lib = nixpkgs.lib;
      outputs = {
        darwinConfigurations."mythique" = nix-darwin.lib.darwinSystem {
          inherit specialArgs;
          modules = [
            self.nixosModules.overlays
            home-manager.darwinModules.default
            darwinRevisionConfig
            ./darwin/mythique.nix
          ];
        };

        nixosConfigurations.hw4 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          inherit specialArgs;
          modules = [
            self.nixosModules.overlays
            disko.nixosModules.disko
            home-manager.nixosModules.default

            ./modules/nelhage.com.nix
            ./modules/common.nix
            ./hw4.nelhage.com/configuration.nix
            ./hw4.nelhage.com/hardware-configuration.nix
          ];
        };

        nixosConfigurations.avdVM = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          inherit specialArgs;
          modules = [
            darwinVMHost
            ./modules/vm-base.nix
            ./modules/avd-vm.nix
          ];
        };

        nixosModules.overlays = {
          nixpkgs.overlays = [
            agenix.overlays.default
            self.overlays.default
          ];
        };

        overlays.default = final: prev: {
          base16-shell = self.packages.${prev.system}.base16-shell;
          obsidian-scan = self.packages.${prev.system}.obsidian-scan;
          hugo = self.packages.${prev.system}.hugo-pinned;
        };

        packages = forAllSystems (
          system:
          let
            pkgs = nixpkgs.legacyPackages.${system};
          in
          {
            base16-shell = pkgs.callPackage ./pkgs/base16-shell.nix { };
            garmindb = pkgs.callPackage ./pkgs/garmindb { python = pkgs.python312; };
            hugo-pinned = pkgs.callPackage ./pkgs/hugo-pinned.nix { };
          }
        );

        devShells = forAllSystems (
          system:
          let
            pkgs = nixpkgs.legacyPackages.${system};
          in
          {
            rules_boost = pkgs.callPackage ./shells/rules_boost.nix { };
            rust = pkgs.callPackage ./shells/rust.nix { };
          }
        );

        templates.default = {
          path = ./template;
          description = "Development template";
          welcomeText = "Add your packages to flake.nix";
        };
      };
    in
    builtins.foldl' lib.attrsets.recursiveUpdate outputs (
      builtins.map (dir: import dir inputs) subdirs
    );
}

See @README.md

## Flake structure

I use a single shared flake to manage all of my infrastructure. `flake.nix` exports a number of outputs:

### `nixosConfigurations.*`

Configuration for Linux machines running NixOS. Primarily my personal dedicated cloud server (hosts nelhage.com, livegrep.com, and other services), but potentially also some virtual machine configurations.

### `darwinConfigurations.*`

Manages my personal mac laptop(s), usually my daily drivers.

### `homeConfigurations.*`

Configuration primarily used for Linux machines **not** running NixOS. Primarily graphical machines where I want to just use Ubuntu for the desktop environment.

## Code structure

- home-manager modules live in `home-manager/`
    - `home-manager/home.nix` is the base configuration used by essentially all of my home-manager configs.
- nixos modules live under `modules/`
- nix-darwin modules live under `darwin/`
- Packages which can be built standalone live under `pkgs/`

## Sharing configuration

In general, I often want all three of the above setups (macOS, NixOS, other Linux) to be able to share configuration. That desire pushes me towards using `home-manager` for many purposes, in place of base NixOS or nix-darwin configuration.

My NixOS and Darwin machines configure `home-manager` through NixOS or nix-darwin, and then include modules shared between them and between other home configurations. I run a number of services out of `home-manager`'s systemd and launchd configuration.

## Reminders

- You must `git add` new files in order for the nix flake to see them.

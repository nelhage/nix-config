# nelhage's `nix` configuration

This repository contains unified `nix` configuration for my personal machines and infrastructure. It also contains some smaller personal projects, for ease of management/deployment on my system.

## Repository structure

I use a single shared flake to manage all of my infrastructure. `flake.nix` exports a number of outputs:

### `nixosConfigurations.*`

Configuration for Linux machines running NixOS. Primarily my personal dedicated cloud server (hosts nelhage.com, livegrep.com, and other services), but potentially also some virtual machine configurations.

### `darwinConfigurations.*`

Manages my personal mac laptop(s), usually my daily drivers.

### `homeConfigurations.*`

Configuration primarily used for Linux machines **not** running NixOS. Primarily graphical machines where I want to just use Ubuntu for the desktop environment.

### `packages.*`

Packages (which all live in `pkgs/`) built out of this repository for use elsewhere.

## Sharing configuration

In general, I often want all three of the above setups (macOS, NixOS, other Linux) to be able to share configuration. That desire pushes me towards using `home-manager` for many purposes, in place of base NixOS or nix-darwin configuration.

My NixOS and Darwin machines configure `home-manager` through NixOS or nix-darwin, and then include modules shared between them and between other home configurations. I run a number of services out of `home-manager`'s systemd and launchd configuration.


## Notable projects in this repository:
- [`obsidian-scan`](pkgs/obsidian-scan) -- See [this blog post](https://blog.nelhage.com/post/personal-software-with-claude/)

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

## Temporary workarounds

When working around something that will be fixed upstream (a vulnerable package, a stale alias, a bad CA root), guard the workaround on the nixpkgs version that fixes it and `throw` once that version arrives, so it can't silently outlive its usefulness:

```nix
emacs =
  if prev.lib.versionAtLeast prev.emacs.version "31" then
    throw ''
      nixpkgs' `emacs` is now version ${prev.emacs.version}, so the emacs31
      alias in this flake is obsolete: remove the `emacs` attribute from
      `overlays.default` in flake.nix.
    ''
  else
    final.emacs31;
```

- Add a comment explaining why the workaround exists (CVE or advisory ID, upstream PR).
- Make the error message say exactly what to delete, with the right file paths, including every place that imports a module (NixOS and nix-darwin).
- Put a workaround that is more than a line or two in its own module (e.g. `modules/<name>.nix`), so removing it is just deleting the file and its imports.
- Before overriding a package in `overlays.default`, check how much it rebuilds (`nix build --dry-run` on hw4's toplevel). Overriding anything low in the dependency graph (curl, brotli, ...) rebuilds a large part of the system. For a security fix, graft a patched build with `system.replaceDependencies.replacements` instead (NixOS only). Note that grafting doesn't rewrite a package's references to its own store path, so un-grafted copies can stay in the closure; check with `nix why-depends`.

## Reminders

- You must `git add` new files in order for the nix flake to see them.

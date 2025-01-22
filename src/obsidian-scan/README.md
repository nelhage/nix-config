# `obsidian-scan`: Performant vault scanning for `obsidian.el`

[`obsidian.el`][obsidianel] is an Emacs mode for interacting with [Obsidian][obsidian] vaults, and for the most part, it's pretty solid.

However, I found it to be unusable as my vault grew due to [performance issues][slow] -- the present version frequently walks the entire vault and parses every note, using minimally-optimized elisp, which takes multiple **minutes** for my vault on my laptop.

This repository contains two components to improve the situation:

- A Rust program, called `obsidian-scan`, which performs the same scanning operation in Rust, outputting key information as a single JSON object.
- `obsidian-scan.el`, which patches `obsidian.el` (using elisp [advice][advice]) to use `obsidian-scan`, instead of the existing code.

The end result is that `obsidian-update` takes under 100ms on my vault, with no caching required, making it viable to call unconditionally on most interactive commands that access the vault.

# Using this repository

- Build the `obsidian-scan` binary via `cargo build --release`
- Install `target/release/obsidian-scan` somewhere on your `PATH`
- Install `emacs/obsidian-scan.el` somewhere on your emacs `load-path`
- Add something like the following to your emacs init file:
  ```elisp
  (with-eval-after-load 'obsidian
    (require 'obsidian-scan))
  ```

[obsidian]: https://obsidian.md/
[obsidianel]: https://github.com/licht1stein/obsidian.el
[slow]: https://github.com/licht1stein/obsidian.el/issues/39
[advice]: https://www.gnu.org/software/emacs/manual/html_node/elisp/Advising-Functions.html

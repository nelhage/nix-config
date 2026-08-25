{ ... }: {
  homebrew = {
    enable = true;
    casks = [
      "monitorcontrol"
      "dash"
      "logi-options+"
      "flux-app"
      "zotero"
      "zoom"
      "steam"
      "iterm2"
      "emacs-app"
      "rectangle"
      "elgato-control-center"
    ];
    onActivation.autoUpdate = true;
  };
}

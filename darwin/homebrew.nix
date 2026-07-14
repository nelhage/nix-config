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
      "emacs-app"
      "rectangle"
      "elgato-control-center"
    ];
    onActivation.autoUpdate = true;
  };
}

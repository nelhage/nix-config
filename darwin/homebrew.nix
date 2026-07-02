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
    ];
    onActivation.autoUpdate = true;
  };
}

{ modulesPath, config, lib, pkgs, ... }: {
  services.openssh.enable = true;

  environment.systemPackages = map lib.lowPrio [ pkgs.curl pkgs.gitMinimal pkgs.emacs pkgs.mosh pkgs.vim];

  environment.defaultPackages = import ./dev-pkgs.nix {inherit pkgs;};

  users.users =
    let
      pubkeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOj/9YTjI5Pr3TrzFMr9ADLTw7yeJZ6jCejXRL9N0rku nelhage@mythique"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIZA2k+GfubMI9WPc9tyX0Vw3xXvUOuaDcrdyNeAzfgf nelhage@pedagogique"
      ];
    in
    {
      root = {
        openssh.authorizedKeys.keys = pubkeys;
      };
      nelhage = {
        openssh.authorizedKeys.keys = pubkeys;
        extraGroups = ["wheel" "docker"];
        group = "nelhage";
        uid = 1000;
        isNormalUser = true;
        description = "Nelson Elhage";
      };
    };
  users.groups.nelhage = { gid = 1000; };

  security.sudo.extraConfig = "nelhage   ALL=(ALL:ALL) NOPASSWD: ALL";
}

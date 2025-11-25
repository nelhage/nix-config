{
  pkgs,
  ...
}:
{
  imports = [
    ./common.nix
    ./home-manager.nix
  ];

  services.openssh = {
    enable = true;
    extraConfig = ''
      AuthenticationMethods publickey
      AllowUsers nelhage
    '';
  };

  users.users.nelhage.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILAc21zLDUk1y2VP2AIUtKhGT5SUrmPN0xI4nFn7bqmU nelhage@pixel-ten"
    "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBFzLlWzdMDU5vbNJNEneUfSoOtMz7xEzfVnfFTvLl/atHO8qKBn97IwmOZwnnxYhEOfnbHk0JB/mA083yQQ2w+M= nelhage@anthropic-laptop"
  ];

  home-manager.users.nelhage =
    { ... }:
    {
      imports = [
        ../home-manager/litestream.nix
      ];

      xdg.configFile."litestream-garmin.yml".source = ./litestream-garmin.yml;

      sync.autocommit.enable = true;
    };
}

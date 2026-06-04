{
  modulesPath,
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ../../modules/nelhage.com.nix
    ../../modules/nixos.nix
    ./hardware-configuration.nix
    ./disk-config.nix
  ];
  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a
    # EF02 partition to the list already
    #
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  networking = {
    hostName = "hw4";
    domain = "nelhage.com";
  };

  boot.swraid.mdadmConf = ''
    MAILADDR nelhage@nelhage.com
    MAILFROM hw4.nelhage.com
  '';

  nelhage.tailscaleAddress = "100.78.93.125";

  system.stateVersion = "23.11";

  systemd.slices = lib.mkMerge [
    (
      let
        inherit (builtins) listToAttrs;
        defaultScopes = [
          "init.scope"
          "system"
          "user"
          "machine"
        ];
      in
      listToAttrs (
        map (scope: {
          name = scope;
          value = {
            sliceConfig = {
              AllowedCPUs = "0-9,12-19";
            };
          };
        }) defaultScopes
      )
    )

    {
      "isolated" = {
        sliceConfig = {
          AllowedCPUs = "10-11";
        };
      };
    }
  ];

  security.acme.certs."lab.nelhage.com" = { };

  # Expose lab.nelhage.com publicly, gated by Google login. The oauth2-proxy
  # engine lives in modules/oauth2-proxy.nix.
  services.oauth2-proxy.nginx.virtualHosts."lab.nelhage.com" = {
    allowed_emails = [ "nelhage@nelhage.com" ];
  };

  # Shared secret that nginx injects (as `proxy_set_header Authorization
  # "token ...";`) so the JupyterLab backend trusts requests that arrived
  # through the oauth2-gated path. nginx (root) reads it for the `include`
  # below; the Jupyter service (running as nelhage) reads the same file to
  # learn the token it should require (see host/hw4/home-nelhage.nix).
  age.secrets."jupyter-auth" = {
    file = ../../secrets/jupyter-auth.age;
    owner = "nelhage";
  };

  services.nginx.virtualHosts."lab.nelhage.com" = {
    useACMEHost = "lab.nelhage.com";
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://localhost:8002";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        # Inject the Jupyter auth token. Trailing `*` makes this a glob so the
        # build-time `nginx -t` (where /run/agenix is absent) still passes; at
        # runtime it matches the agenix-decrypted file. If the secret is ever
        # missing, the header is simply absent and Jupyter fails closed.
        include ${config.age.secrets."jupyter-auth".path}*;
      '';
      recommendedProxySettings = false;
    };
  };

  home-manager.users.nelhage = import ./home-nelhage.nix;
}

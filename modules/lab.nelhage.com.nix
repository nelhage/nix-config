{ config, ... }: {
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
    file = ../secrets/jupyter-auth.age;
    owner = "nelhage";
    group = "nginx";
    mode = "440";
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

  home-manager.users.nelhage = {
    nelhage.jupyterlab.enable = true;
    # Authentication is handled upstream: lab.nelhage.com is gated by oauth2-proxy
    # (Google login), and nginx injects an `Authorization: token ...` header on
    # that path from the `jupyter-auth` secret (see host/hw4/nixos.nix). We read
    # the token out of that same secret here so Jupyter requires it; direct
    # requests to 127.0.0.1:8002 without the header are rejected. The secret
    # holds an nginx directive line, so we pull the token out with a regex.
    nelhage.jupyterlab.extraConfig = ''
      import pathlib, re

      c.ServerApp.allow_remote_access = True
      c.IdentityProvider.token = re.search(
          r'token ([^"]+)"',
          pathlib.Path("/run/agenix/jupyter-auth").read_text(),
      ).group(1)
    '';
  };
}

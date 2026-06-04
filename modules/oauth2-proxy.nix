# OAuth2 authentication gateway for *.nelhage.com services.
#
# This is the reusable "engine". To put a service behind Google login, add it
# in the host config, e.g.:
#
#   services.oauth2-proxy.nginx.virtualHosts."svc.nelhage.com" = {
#     allowed_emails = [ "nelhage@nelhage.com" ];
#   };
#
# and define the `svc.nelhage.com` nginx virtualHost as usual. The oauth2-proxy
# nginx module injects the `auth_request` machinery into each protected vhost
# and redirects unauthenticated users to the shared `auth.nelhage.com` flow.
#
# All protected vhosts share one Google OAuth client and one redirect URI
# (https://auth.nelhage.com/oauth2/callback); the session cookie is scoped to
# `.nelhage.com` so a single login covers every subdomain.
{ config, ... }:
{
  services.oauth2-proxy = {
    enable = true;
    provider = "google";

    # The OAuth client ID is not secret. Replace with the value from the
    # Google Cloud console (see the setup notes). The matching client secret
    # and the cookie secret are supplied via the agenix keyFile below.
    clientID = "449621192813-tuocchfueagk69h59t8pkq9ggukmt237.apps.googleusercontent.com";
    keyFile = config.age.secrets."oauth2-proxy.env".path;

    # Let any Google account complete the login flow; the actual allow-list is
    # enforced per-vhost via `allowed_emails` (see host config). This is the
    # pattern the upstream nginx module is built around.
    email.domains = [ "*" ];

    # Needed for nginx auth_request mode: exposes the authenticated identity to
    # backends via X-User / X-Email and lets nginx see X-Forwarded-* headers.
    setXauthrequest = true;
    reverseProxy = true;

    redirectURL = "https://auth.nelhage.com/oauth2/callback";

    # Login happens on auth.nelhage.com but redirects back to the originating
    # service (e.g. lab.nelhage.com). oauth2-proxy drops cross-host redirects
    # unless the target domain is whitelisted; the leading dot covers every
    # *.nelhage.com subdomain.
    extraConfig.whitelist-domain = ".nelhage.com";

    # Scope the session cookie to the whole apex domain so one login is shared
    # across every protected *.nelhage.com service.
    cookie.domain = ".nelhage.com";

    nginx.domain = "auth.nelhage.com";
  };

  age.secrets."oauth2-proxy.env".file = ../secrets/oauth2-proxy.env.age;

  # The central auth endpoint. The oauth2-proxy nginx module automatically adds
  # the `/oauth2/` location here; everything else just 404s.
  security.acme.certs."auth.nelhage.com" = { };
  services.nginx.virtualHosts."auth.nelhage.com" = {
    useACMEHost = "auth.nelhage.com";
    forceSSL = true;
    locations."/".return = "404";
  };
}

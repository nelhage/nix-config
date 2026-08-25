# Render a base16-shell theme into an iTerm2 "dynamic profile", so the colors
# are already in effect before any shell runs, and survive a `reset`.
#
# Returns a function; call it with a theme name and a GUID to get the JSON.
{
  lib,
  runCommand,
  writeText,
  python3,
  base16-shell,
}:
let
  generator = writeText "base16-to-iterm2.py" ''
    import json
    import os
    import sys

    def color(spec):
        # base16-shell writes colors as "rr/gg/bb"; iTerm2 wants floats.
        r, g, b = (int(c, 16) / 255.0 for c in spec.split("/"))
        return {
            "Color Space": "sRGB",
            "Red Component": r,
            "Green Component": g,
            "Blue Component": b,
            "Alpha Component": 1.0,
        }

    env = os.environ
    # The non-ANSI entries mirror the iTerm2-specific escapes (Pg..Pm) that the
    # base16-shell scripts emit.
    colors = {"Ansi %d Color" % i: env["color%02d" % i] for i in range(16)}
    colors.update(
        {
            "Foreground Color": env["color_foreground"],
            "Background Color": env["color_background"],
            "Bold Color": env["color_foreground"],
            "Selection Color": env["color19"],
            "Selected Text Color": env["color_foreground"],
            "Cursor Color": env["color_foreground"],
            "Cursor Text Color": env["color_background"],
        }
    )

    profile = {
        "Name": env["profileName"],
        "Guid": env["guid"],
        # Inherit everything that isn't a color from the profile we're shadowing.
        "Dynamic Profile Parent Name": env["parentName"],
    }
    for key, spec in colors.items():
        value = color(spec)
        # A profile with "Use Separate Colors for Light and Dark Mode" reads the
        # suffixed keys instead of the bare one, so write all three.
        for suffix in ("", " (Light)", " (Dark)"):
            profile[key + suffix] = value

    json.dump({"Profiles": [profile]}, sys.stdout, indent=2)
    sys.stdout.write("\n")
  '';
in
{
  theme,
  guid,
  profileName ? "base16-${theme}",
  parentName ? "Default",
}:
runCommand "iterm2-dynamic-profile-${theme}.json"
  {
    nativeBuildInputs = [ python3 ];
    inherit
      guid
      profileName
      parentName
      ;
  }
  ''
    script=${lib.escapeShellArg base16-shell}/bin/base16-${theme}
    test -x "$script"

    # The theme scripts are a block of `colorNN=...` assignments followed by the
    # code that emits the escape sequences. Keep just the assignments (some of
    # which reference earlier ones) and source them for their values.
    set -a
    eval "$(grep -E '^color[0-9a-z_]+=' "$script")"
    set +a

    python3 ${generator} > $out
  ''

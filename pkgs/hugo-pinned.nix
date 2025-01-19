{
  hugo,
  fetchFromGitHub,
}:
# Pinned Hugo, so I can update at my own pace and not break my blogs.
hugo.overrideAttrs rec {
  version = "0.127.0";
  src = fetchFromGitHub {
    owner = "gohugoio";
    repo = "hugo";
    tag = "v${version}";
    hash = "sha256-QAZP119VOPTnVXe2mtzCpB3OW/g73oA/qwR94OzISKo=";
  };
  vendorHash = "sha256-Og7FTCrto1l+Xpfr2zEgg/yXa7dflws0yJ2Xh9f3mbI=";
}

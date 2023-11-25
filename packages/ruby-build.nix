{ pkgs ? import <nixpkgs> { } }:
with pkgs;
let
in
stdenv.mkDerivation rec {
  pname = "ruby-build";
  version = "20231114";

  src = fetchFromGitHub {
    owner = "rbenv";
    repo = "ruby-build";
    rev = "v${version}";
    # NOTE:  Calculate sha256
    # nix-shell -p nix-prefetch-git jq --run "nix hash to-sri sha256:\$(nix-prefetch-git --url https://github.com/rbenv/ruby-build --quiet --rev v20230424 | jq -r '.sha256')"
    sha256 = "sha256-dsmBhevcYWTajnt3aQO6qloQhuMt22mnn4mFW2gQBIQ=";
  };

  nativeBuildInputs = [
      pkg-config
      libyaml
      readline
      gmp
  ];

  phases = [
    "unpackPhase"
    "installPhase"
  ];

  installPhase = ''
    set -e

    BIN_PATH="$out/bin"
    SHARE_PATH="$out/share/ruby-build"

    mkdir -p "$BIN_PATH" "$SHARE_PATH"

    install -p bin/* "$BIN_PATH"
    install -p -m 0644 share/ruby-build/* "$SHARE_PATH"
  '';
}

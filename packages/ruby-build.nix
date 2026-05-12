{ pkgs ? import <nixpkgs> { } }:
with pkgs;
let
in
stdenv.mkDerivation rec {
  pname = "ruby-build";
  version = "v20260512";

  src = fetchFromGitHub {
    owner = "rbenv";
    repo = "ruby-build";
    rev = "${version}";
    # NOTE:  Calculate sha256
    # make ruby-build
    sha256 = "sha256-1T2j9VgMw1SxG01pJFK+TTrnaxsrMIXaeKIqu01Bvs0=";
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

{ pkgs ? import <nixpkgs> { } }:
with pkgs;
rustPlatform.buildRustPackage rec {
  pname = "leaf";
  version = "1.28.3";

  src = fetchFromGitHub {
    owner = "RivoLink";
    repo = "leaf";
    rev = "${version}";
    sha256 = "sha256-C37w35/PvokDEMaIwgSJ9GtAKkYRi1vNP7BfdTwTFCo=";
  };

  cargoHash = "sha256-OaG6LXKG2kda/Q1/jEBtetUGaX7YC8KwgI+MAd3Q9yg=";

  nativeBuildInputs = [ pkg-config ];

  doCheck = false;

  meta = with lib; {
    description = "A friendly terminal Markdown previewer";
    homepage = "https://github.com/RivoLink/leaf";
    license = licenses.mit;
    mainProgram = "leaf";
  };
}

{ pkgs ? import <nixpkgs> { } }:
with pkgs;
rustPlatform.buildRustPackage rec {
  pname = "leaf";
  version = "1.29.3";

  src = fetchFromGitHub {
    owner = "RivoLink";
    repo = "leaf";
    rev = "${version}";
    sha256 = "sha256-/gV1jzY5fo0DzCCTD8MKb9U0CCUpSC1EsnmTKjJGZAE=";
  };

  cargoHash = "sha256-cxi+nM5dQ5gF5aKmbq+SO+pF7lBmypZaPw+tVmpYYMs=";

  nativeBuildInputs = [ pkg-config ];

  doCheck = false;

  meta = with lib; {
    description = "A friendly terminal Markdown previewer";
    homepage = "https://github.com/RivoLink/leaf";
    license = licenses.mit;
    mainProgram = "leaf";
  };
}

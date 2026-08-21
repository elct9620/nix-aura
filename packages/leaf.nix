{ pkgs ? import <nixpkgs> { } }:
with pkgs;
rustPlatform.buildRustPackage rec {
  pname = "leaf";
  version = "1.28.0";

  src = fetchFromGitHub {
    owner = "RivoLink";
    repo = "leaf";
    rev = "${version}";
    sha256 = "sha256-eCSGZ+fBc1fxVBQdZgpZYkop2mO1mVPDylXIVK/C2JE=";
  };

  cargoHash = "sha256-B0hYSG00C3my2TcGE+rfziTW9r3HZH+8MAHFQq6uiIk=";

  nativeBuildInputs = [ pkg-config ];

  doCheck = false;

  meta = with lib; {
    description = "A friendly terminal Markdown previewer";
    homepage = "https://github.com/RivoLink/leaf";
    license = licenses.mit;
    mainProgram = "leaf";
  };
}

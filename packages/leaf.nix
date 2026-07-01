{ pkgs ? import <nixpkgs> { } }:
with pkgs;
rustPlatform.buildRustPackage rec {
  pname = "leaf";
  version = "1.25.0";

  src = fetchFromGitHub {
    owner = "RivoLink";
    repo = "leaf";
    rev = "${version}";
    sha256 = "sha256-OSx797tkwjKU9j+0AhQIT7uLM75PzHVw12d5LG6vT3Q=";
  };

  cargoHash = "sha256-rEISBL5vWYP5UKFKWLA2RxlqDBFTz8qPpiPOfxeNUFQ=";

  nativeBuildInputs = [ pkg-config ];

  doCheck = false;

  meta = with lib; {
    description = "A friendly terminal Markdown previewer";
    homepage = "https://github.com/RivoLink/leaf";
    license = licenses.mit;
    mainProgram = "leaf";
  };
}

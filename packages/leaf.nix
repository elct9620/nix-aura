{ pkgs ? import <nixpkgs> { } }:
with pkgs;
rustPlatform.buildRustPackage rec {
  pname = "leaf";
  version = "1.22.2";

  src = fetchFromGitHub {
    owner = "RivoLink";
    repo = "leaf";
    rev = "${version}";
    sha256 = "sha256-zpKKChKlKRwoPHfSNBHNuH11ZQRH5jQyhU9OeDckO1I=";
  };

  cargoHash = "sha256-PpbluFMNdfCF4onArZsmXtYSE2Fkd2n4WYCkPLDYkX8=";

  nativeBuildInputs = [ pkg-config ];

  doCheck = false;

  meta = with lib; {
    description = "A friendly terminal Markdown previewer";
    homepage = "https://github.com/RivoLink/leaf";
    license = licenses.mit;
    mainProgram = "leaf";
  };
}

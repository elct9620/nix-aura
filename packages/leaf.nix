{ pkgs ? import <nixpkgs> { } }:
with pkgs;
rustPlatform.buildRustPackage rec {
  pname = "leaf";
  version = "1.27.1";

  src = fetchFromGitHub {
    owner = "RivoLink";
    repo = "leaf";
    rev = "${version}";
    sha256 = "sha256-JYKahP0dEineUKziR2uuxrVpZagtZr912m4Y4OBoloo=";
  };

  cargoHash = "sha256-svfLThsZt3brVTlAloZizJuGlmnaiQIwjANg3oBCTIk=";

  nativeBuildInputs = [ pkg-config ];

  doCheck = false;

  meta = with lib; {
    description = "A friendly terminal Markdown previewer";
    homepage = "https://github.com/RivoLink/leaf";
    license = licenses.mit;
    mainProgram = "leaf";
  };
}

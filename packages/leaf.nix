{ pkgs ? import <nixpkgs> { } }:
with pkgs;
rustPlatform.buildRustPackage rec {
  pname = "leaf";
  version = "1.24.2";

  src = fetchFromGitHub {
    owner = "RivoLink";
    repo = "leaf";
    rev = "${version}";
    sha256 = "sha256-mKB3x7HaO48uMzxaKpep+69D52RgIKTtvVNdm/EOJaU=";
  };

  cargoHash = "sha256-GPCU2L3gDj4QOlg3MJ+OndnM2P0jUA+cIuSOhEEZHrU=";

  nativeBuildInputs = [ pkg-config ];

  doCheck = false;

  meta = with lib; {
    description = "A friendly terminal Markdown previewer";
    homepage = "https://github.com/RivoLink/leaf";
    license = licenses.mit;
    mainProgram = "leaf";
  };
}

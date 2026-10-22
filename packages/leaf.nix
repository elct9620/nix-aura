{ pkgs ? import <nixpkgs> { } }:
with pkgs;
rustPlatform.buildRustPackage rec {
  pname = "leaf";
  version = "1.29.1";

  src = fetchFromGitHub {
    owner = "RivoLink";
    repo = "leaf";
    rev = "${version}";
    sha256 = "sha256-+J8c6aoM2GqZMJe2XUiY4A6T1qqw1s1+kVMhdHKSt8o=";
  };

  cargoHash = "sha256-pbzCRd6BoImGL2DXInGRiiobk1CnMEmmeH1tetzNLnQ=";

  nativeBuildInputs = [ pkg-config ];

  doCheck = false;

  meta = with lib; {
    description = "A friendly terminal Markdown previewer";
    homepage = "https://github.com/RivoLink/leaf";
    license = licenses.mit;
    mainProgram = "leaf";
  };
}

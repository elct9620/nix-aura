{ pkgs ? import <nixpkgs> { } }:
with pkgs;
rustPlatform.buildRustPackage rec {
  pname = "leaf";
  version = "1.28.2";

  src = fetchFromGitHub {
    owner = "RivoLink";
    repo = "leaf";
    rev = "${version}";
    sha256 = "sha256-WX9C4gWNPCHWFsHN4xFmShv6dJyYAVgr9xMw5JtoFHI=";
  };

  cargoHash = "sha256-T6GH+Y9zBzSOp54shKtboydIZGPSsSKjuexQ3pQ1FqY=";

  nativeBuildInputs = [ pkg-config ];

  doCheck = false;

  meta = with lib; {
    description = "A friendly terminal Markdown previewer";
    homepage = "https://github.com/RivoLink/leaf";
    license = licenses.mit;
    mainProgram = "leaf";
  };
}

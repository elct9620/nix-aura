{ pkgs ? import <nixpkgs> { } }:
with pkgs;
rustPlatform.buildRustPackage rec {
  pname = "leaf";
  version = "1.19.1";

  src = fetchFromGitHub {
    owner = "RivoLink";
    repo = "leaf";
    rev = "${version}";
    sha256 = "sha256-HCQ/nApCmXr2UYS4tRTR7IZR1Y70cUq0rfJNSf8W5V4=";
  };

  cargoHash = "sha256-RRU+4qvqhhNtcDdToWfD8NhyYgDQwqXn0I2fN9v9YjQ=";

  nativeBuildInputs = [ pkg-config ];

  doCheck = false;

  meta = with lib; {
    description = "A friendly terminal Markdown previewer";
    homepage = "https://github.com/RivoLink/leaf";
    license = licenses.mit;
    mainProgram = "leaf";
  };
}

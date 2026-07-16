{ pkgs ? import <nixpkgs> { } }:
with pkgs;
rustPlatform.buildRustPackage rec {
  pname = "leaf";
  version = "1.26.1";

  src = fetchFromGitHub {
    owner = "RivoLink";
    repo = "leaf";
    rev = "${version}";
    sha256 = "sha256-faZ3yiAdPbN1Pxf7Gss62eYUJzaJ3ZF5BZyCVqHOC4s=";
  };

  cargoHash = "sha256-evHpyavHLJxStN8ZYDetwzxh18eQX9Nq3KL3kudk7dI=";

  nativeBuildInputs = [ pkg-config ];

  doCheck = false;

  meta = with lib; {
    description = "A friendly terminal Markdown previewer";
    homepage = "https://github.com/RivoLink/leaf";
    license = licenses.mit;
    mainProgram = "leaf";
  };
}

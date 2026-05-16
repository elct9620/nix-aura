{ pkgs ? import <nixpkgs> { } }:
with pkgs;
rustPlatform.buildRustPackage rec {
  pname = "agent-browser";
  version = "0.27.0";

  src = fetchFromGitHub {
    owner = "vercel-labs";
    repo = "agent-browser";
    rev = "v${version}";
    # NOTE: Calculate sha256
    # make agent-browser
    sha256 = "sha256-c+AJAXMX88t+zzFsEAtFJDjDY5EbhmEyMRGFL4t63nE=";
  };

  cargoRoot = "cli";
  buildAndTestSubdir = "cli";

  cargoHash = "sha256-2u7yokHCxIVq16370Mg+n5kf03yUDYJmctFxN1fnaAA=";

  nativeBuildInputs = [ pkg-config ];

  doCheck = false;

  meta = with lib; {
    description = "Browser automation CLI for AI agents";
    homepage = "https://github.com/vercel-labs/agent-browser";
    license = licenses.asl20;
    mainProgram = "agent-browser";
  };
}

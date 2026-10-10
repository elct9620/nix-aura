{ pkgs ? import <nixpkgs> { } }:
with pkgs;
rustPlatform.buildRustPackage rec {
  pname = "agent-browser";
  version = "0.39.0";

  src = fetchFromGitHub {
    owner = "vercel-labs";
    repo = "agent-browser";
    rev = "v${version}";
    # NOTE: Calculate sha256
    # make agent-browser
    sha256 = "sha256-8Og2ruMaY+ObT9WiYqCyoXAcwZ/6t2g6SeU3+wF15ck=";
  };

  cargoRoot = "cli";
  buildAndTestSubdir = "cli";

  cargoHash = "sha256-Axpnef0CrrFcYBvfNxPYUZ4hxaP9rfpqUI8GSL49bu4=";

  nativeBuildInputs = [ pkg-config ];

  doCheck = false;

  # The CLI resolves its skills at runtime by walking up from the executable to
  # find a directory containing `skills/` (see cli/src/skills.rs). Ship both the
  # discovery stubs (`skills/`) and the runtime content (`skill-data/`) alongside
  # the binary so `$out/bin/../skills` resolves and `skill-data/` is picked up too.
  # AGENT_BROWSER_SKILLS_DIR is intentionally not used: it only accepts a single
  # directory and would leave out `skill-data/`.
  postInstall = ''
    cp -r "$src/skills" "$src/skill-data" "$out/"
  '';

  meta = with lib; {
    description = "Browser automation CLI for AI agents";
    homepage = "https://github.com/vercel-labs/agent-browser";
    license = licenses.asl20;
    mainProgram = "agent-browser";
  };
}

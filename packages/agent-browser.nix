{ pkgs ? import <nixpkgs> { } }:
with pkgs;
rustPlatform.buildRustPackage rec {
  pname = "agent-browser";
  version = "0.37.1";

  src = fetchFromGitHub {
    owner = "vercel-labs";
    repo = "agent-browser";
    rev = "v${version}";
    # NOTE: Calculate sha256
    # make agent-browser
    sha256 = "sha256-AgpKazIBT3CKd4Q7yQsEGhoTW+7R0Pflma6aH+6UI/U=";
  };

  cargoRoot = "cli";
  buildAndTestSubdir = "cli";

  cargoHash = "sha256-ziN4UMeEcgsD5BDXWjffreGjyew7oTUtq59b/Um8Dfk=";

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

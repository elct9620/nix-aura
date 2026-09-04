{ pkgs ? import <nixpkgs> { } }:
with pkgs;
let
  # `scripts/vendor.sh` curls the tree-sitter runtime and two grammars; the
  # sandbox has no network, so fetch them as fixed-output inputs and lay them
  # down where the script expects before it looks.
  runtimeVersion = "v0.26.12";
  rubyVersion = "v0.23.1";
  rustVersion = "v0.24.2";
  markdownVersion = "v0.5.3";

  treeSitter = fetchFromGitHub {
    owner = "tree-sitter";
    repo = "tree-sitter";
    rev = runtimeVersion;
    hash = "sha256-Fyp3eyvvP8NFVgGt+RxBA1Q2ujNVXgGr6SvDCMDas0Q=";
  };

  treeSitterRuby = fetchFromGitHub {
    owner = "tree-sitter";
    repo = "tree-sitter-ruby";
    rev = rubyVersion;
    hash = "sha256-iu3MVJl0Qr/Ba+aOttmEzMiVY6EouGi5wGOx5ofROzA=";
  };

  treeSitterRust = fetchFromGitHub {
    owner = "tree-sitter";
    repo = "tree-sitter-rust";
    rev = rustVersion;
    hash = "sha256-Ls6tB6IxXDQDWwx0BJ7RgbheelC4MH8z97E7wwhkDcY=";
  };

  # One repository, two grammars: the block grammar for a specification's
  # structure, and the inline one for the text a block-level node holds.
  treeSitterMarkdown = fetchFromGitHub {
    owner = "tree-sitter-grammars";
    repo = "tree-sitter-markdown";
    rev = markdownVersion;
    hash = "sha256-WUVN7+lzDI+VC5PuJjhHiS4JpVr1x0Ic30i2tVrI6W8=";
  };
in
stdenv.mkDerivation rec {
  pname = "sumitsubo";
  version = "0.1.0-preview7";

  src = fetchFromGitHub {
    owner = "elct9620";
    repo = "sumitsubo";
    rev = "v${version}";
    hash = "sha256-Sla9GXVfhpkAeAmUoYFenMR8am0om9XcOSERH0aFGQo=";
  };

  nativeBuildInputs = [ spinel ];

  # Fail loudly rather than silently building against another grammar than the
  # queries are written for, if upstream re-pins one.
  postPatch = ''
    check() {
      pinned=$(sed -n "s/^$1=//p" scripts/vendor.sh)
      if [ "$pinned" != "$2" ]; then
        echo "error: vendor.sh pins $1 $pinned, but this derivation fetches $2." >&2
        exit 1
      fi
    }
    check RUNTIME ${runtimeVersion}
    check RUBY ${rubyVersion}
    check RUST ${rustVersion}
    check MARKDOWN ${markdownVersion}

    # vendor.sh skips a fetch whose stamp already names the pinned tag, so
    # staging the sources with their stamps leaves it doing only the part that
    # needs no network: the header copy the binding compiles against, and the
    # include roots the runtime's own sources reach through.
    mkdir -p vendor
    cp -r --no-preserve=mode ${treeSitter} vendor/tree-sitter
    cp -r --no-preserve=mode ${treeSitterRuby} vendor/tree-sitter-ruby
    cp -r --no-preserve=mode ${treeSitterRust} vendor/tree-sitter-rust
    cp -r --no-preserve=mode ${treeSitterMarkdown} vendor/tree-sitter-markdown
    echo ${runtimeVersion} > vendor/tree-sitter.pin
    echo ${rubyVersion} > vendor/tree-sitter-ruby.pin
    echo ${rustVersion} > vendor/tree-sitter-rust.pin
    echo ${markdownVersion} > vendor/tree-sitter-markdown.pin
    ./scripts/vendor.sh

    # The revision the executable answers for is read from git, and a source
    # tarball carries no .git -- which would stamp it "unknown", the string the
    # project treats as "this build cannot say where it came from". Hand it the
    # revision of the tag this derivation fetches.
    substituteInPlace scripts/build_rev.sh \
      --replace-fail 'rev=$(git -C "$root" rev-parse --short=7 HEAD 2>/dev/null || echo unknown)' \
                     'rev=f610d2a'
    ./scripts/build_rev.sh
  '';

  # `spin` derives the runtime headers it compiles carried C against from its
  # own location, so it is invoked by path rather than by bare name. Its cache
  # of compiled objects lives under $HOME, which the sandbox does not give it.
  buildPhase = ''
    runHook preBuild
    export HOME=$TMPDIR
    ${spinel}/bin/spin build
    runHook postBuild
  '';

  # Each test compares its output against a committed snapshot. The binding is
  # tested on its own terms: it owns the record format the application reads
  # back, and holding that needs neither the runtime nor a grammar.
  doCheck = true;
  checkPhase = ''
    runHook preCheck
    ${spinel}/bin/spin test
    (cd .packages/tree-sitter && ${spinel}/bin/spin test)
    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 build/bin/sumi $out/bin/sumi
    runHook postInstall
  '';

  # `spin test` never compiles bin/, so the wiring that ships -- the revision
  # among it -- is exercised only by running the executable itself.
  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    got=$($out/bin/sumi -v)
    echo "$got"
    echo "$got" | grep -Eq '\([0-9a-f]{7}\)$' || {
      echo "error: the executable was not stamped: $got" >&2
      exit 1
    }
    runHook postInstallCheck
  '';

  meta = with lib; {
    description = "AST-based linter verifying code stays aligned with its specification";
    homepage = "https://github.com/elct9620/sumitsubo";
    license = licenses.asl20;
    mainProgram = "sumi";
  };
}

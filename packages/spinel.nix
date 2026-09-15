{ pkgs ? import <nixpkgs> { } }:
with pkgs;
stdenv.mkDerivation rec {
  pname = "spinel";
  version = "2026.09.12";

  # The release tarball (`make dist`), not the tag's source archive: it vendors
  # prism and rbs so `make deps` needs no network, and records in .spinel-dist
  # the revision and release a git-less tree cannot derive.
  src = fetchurl {
    url = "https://github.com/matz/spinel/releases/download/${version}/spinel-${version}.tar.xz";
    hash = "sha256-G7omnPyABLzWC3VHHNROrM3Gbu1gsfY20TZ8iXx2Snc=";
  };

  nativeBuildInputs = [ makeWrapper ];

  # This release's Makefile still reads the revision and release from git, so
  # the build would record "unknown" / "unreleased" -- and spin reads the
  # revision back as the toolchain key its probe records are stored under,
  # where "unknown" means no key at all. Mirror upstream 7e938c31, which falls
  # back to .spinel-dist; drop this once a release ships with that change.
  postPatch = ''
    substituteInPlace Makefile \
      --replace-fail 'git rev-parse --short=12 HEAD 2>/dev/null || echo unknown' \
                     'git rev-parse --short=12 HEAD 2>/dev/null' \
      --replace-fail 'case "$$d" in' \
                     'if [ -z "$$r" ] && [ -f .spinel-dist ]; then r=$$(sed -n 1p .spinel-dist); d=$$(sed -n 2p .spinel-dist); fi; [ -n "$$r" ] || r=unknown; case "$$d" in'
  '';

  makeFlags = [ "PREFIX=${placeholder "out"}" ];

  enableParallelBuilding = true;

  # The test suite compares against a reference CRuby and clones ruby/spec.
  doCheck = false;

  # spinel shells out to `cc` to compile the C it generates, and defaults to
  # whatever `cc` PATH resolves to. Pin it to the toolchain this was built
  # with so a generated binary does not depend on the user's environment.
  # spin additionally drives git for its package index and git dependencies.
  postInstall = ''
    wrapProgram $out/lib/spinel/spinel \
      --prefix PATH : ${lib.makeBinPath [ stdenv.cc ]}
    wrapProgram $out/lib/spinel/spin \
      --prefix PATH : ${lib.makeBinPath [ stdenv.cc git ]}
  '';

  # A spinel that builds is not yet a spinel that works: the compiler reaches
  # for the runtime headers of its own install, so a header the install left
  # behind fails no build here and every build afterwards. Compile and run the
  # smallest possible program through the installed toolchain to catch that.
  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    export HOME=$TMPDIR
    workdir=$(mktemp -d)
    echo 'puts "ok"' > $workdir/hello.rb
    (cd $workdir && $out/bin/spinel hello.rb -o hello && ./hello)
    runHook postInstallCheck
  '';

  meta = with lib; {
    description = "Ruby ahead-of-time compiler producing standalone native executables";
    homepage = "https://github.com/matz/spinel";
    license = licenses.mit;
    mainProgram = "spinel";
  };
}

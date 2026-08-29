{ pkgs ? import <nixpkgs> { } }:
with pkgs;
let
  # `make deps` curls these two gems for their bundled C sources; the sandbox
  # has no network, so fetch them as fixed-output inputs and stage vendor/
  # before make looks at it.
  prismVersion = "1.9.0";
  rbsVersion = "4.0.1";

  prismGem = fetchurl {
    url = "https://rubygems.org/gems/prism-${prismVersion}.gem";
    hash = "sha256-e1MMap+SwkMAAUkZydy8BVv0zfUewwrtCZsGzWZ074U=";
  };

  rbsGem = fetchurl {
    url = "https://rubygems.org/gems/rbs-${rbsVersion}.gem";
    hash = "sha256-4jf9SXh/smW/DzifLw9XiP3N8fSbtUtPeVLOqQQWKgc=";
  };

  rev = "5a63653cf61345efe4e0b8ed32103b63e8b8e708";
in
stdenv.mkDerivation rec {
  pname = "spinel";
  # Upstream publishes no releases; pinned to a master commit.
  version = "0-unstable-2026-08-29";

  src = fetchFromGitHub {
    owner = "matz";
    repo = "spinel";
    inherit rev;
    hash = "sha256-auNkdE3/Hihz8hWOMhOI7IwyHV4OyGMFVJLge/prNO0=";
  };

  nativeBuildInputs = [ makeWrapper ];

  # Fail loudly rather than silently building against the wrong parser if
  # upstream moves either version.
  postPatch = ''
    check() {
      pinned=$(sed -n "s/^$1 ?= //p" Makefile)
      if [ "$pinned" != "$2" ]; then
        echo "error: Makefile pins $1 $pinned, but this derivation fetches $2." >&2
        exit 1
      fi
    }
    check PRISM_VERSION ${prismVersion}
    check RBS_VERSION ${rbsVersion}

    # The Makefile reads the build revision from git for `spinel --version`.
    # A source tarball carries no .git, so the build would record "unknown" --
    # and spin reads that string back as the toolchain version keying its probe
    # records, where "unknown" means "no version at all". Hand it the pinned rev.
    substituteInPlace Makefile \
      --replace-fail 'git rev-parse --short=12 HEAD 2>/dev/null || echo unknown' \
                     'echo ${builtins.substring 0 12 rev}'

    mkdir -p vendor/prism vendor/rbs
    tar -xf ${prismGem} -O data.tar.gz | tar -xz -C vendor/prism
    tar -xf ${rbsGem} -O data.tar.gz | tar -xz -C vendor/rbs
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
    # The install rule enumerates headers by name and has fallen behind lib/:
    # spinel_rt.h includes sp_process_status.h unconditionally, but install
    # never copies it, so an installed toolchain compiles nothing at all.
    # Drop this once upstream's install rule covers the header (matz/spinel#4186).
    install -m 644 lib/sp_process_status.h $out/lib/spinel/lib/

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

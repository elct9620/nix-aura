{ pkgs ? import <nixpkgs> { } }:
with pkgs;
stdenv.mkDerivation rec {
  pname = "spinel";
  version = "2026.10.25";

  # The release tarball (`make dist`), not the tag's source archive: it vendors
  # prism and rbs so `make deps` needs no network, and records in .spinel-dist
  # the revision and release a git-less tree cannot derive.
  src = fetchurl {
    url = "https://github.com/matz/spinel/releases/download/${version}/spinel-${version}.tar.xz";
    hash = "sha256-4TxzYOT4RbSmufNKgPtrgn+VCkgNGqM55ssl5ctho7A=";
  };

  # The build generates lib/spinel_rt_responds_generated.h with a Ruby script
  # (tools/gen_respond_to_tables.rb) that the dist tarball does not pre-render.
  nativeBuildInputs = [ makeWrapper ruby ];

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

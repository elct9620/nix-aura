{ pkgs ? import <nixpkgs> { } }:
with pkgs;
let
  # Not in nixpkgs; 0.2.0 only ships a wheel on PyPI.
  jupyter-mimetypes = python3Packages.buildPythonPackage rec {
    pname = "jupyter_mimetypes";
    version = "0.2.0";
    format = "wheel";

    src = python3Packages.fetchPypi {
      inherit pname version format;
      dist = "py3";
      python = "py3";
      sha256 = "e6dcd989258e3fc944365b656d9173191517e0e393bd878e97ce500e5b388527";
    };

    dependencies = with python3Packages; [
      pyarrow
      typing-extensions
    ];

    meta = with lib; {
      description = "MIME types support for Jupyter";
      homepage = "https://github.com/datalayer/jupyter-mimetypes";
      license = licenses.bsd3;
    };
  };

  # Not in nixpkgs; 0.9.0 only ships a wheel on PyPI.
  jupyter-kernel-client = python3Packages.buildPythonPackage rec {
    pname = "jupyter_kernel_client";
    version = "0.9.0";
    format = "wheel";

    src = python3Packages.fetchPypi {
      inherit pname version format;
      dist = "py3";
      python = "py3";
      sha256 = "77acb8f2f738d97625d6bd01ee8cf21c4d59790b7ba464108712db3870416f20";
    };

    dependencies = with python3Packages; [
      jupyter-client
      jupyter-core
      jupyter-mimetypes
      requests
      traitlets
      typing-extensions
      websocket-client
    ];

    meta = with lib; {
      description = "Jupyter Kernel Client through HTTP and WebSocket";
      homepage = "https://github.com/datalayer/jupyter-kernel-client";
      license = licenses.bsd3;
    };
  };
in
python3Packages.buildPythonApplication rec {
  pname = "google-colab-cli";
  version = "0.8.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "googlecolab";
    repo = "google-colab-cli";
    rev = "v${version}";
    # NOTE: Calculate sha256
    # make google-colab-cli
    sha256 = "sha256-/sAyxmZNERy56LUlghvN7O/U4oSfQMk1tE70tMpsA+s=";
  };

  build-system = with python3Packages; [
    hatchling
    hatch-vcs
  ];

  dependencies = with python3Packages; [
    click
    filelock
    google-auth
    google-auth-oauthlib
    html2text
    jupyter-kernel-client
    keyring
    nbformat
    packaging
    prompt-toolkit
    pydantic
    pygments
    requests
    rich
    typer
    typing-extensions
    websocket-client
  ];

  # Upstream pins newer minimums than nixpkgs ships; relax and rely on
  # runtime verification.
  pythonRelaxDeps = [
    "filelock"
    "google-auth"
    "google-auth-oauthlib"
    "pydantic"
    "rich"
    "typer"
  ];

  # The wrapped interpreter is a bare python whose site-packages are only
  # added by the wrapper script, so anything re-launched via `sys.executable`
  # cannot import colab_cli or pip:
  # - ssh's ProxyCommand re-launches the CLI; point it at the wrapped entry.
  # - Self-update would pip-install into the read-only store; updates go
  #   through nix-aura, so refuse it and keep the banner pointing there.
  postPatch = ''
    substituteInPlace src/colab_cli/commands/ssh.py \
      --replace-fail 'argv = [sys.executable, "-m", "colab_cli.cli"]' \
                     "argv = [\"$out/bin/colab\"]"

    substituteInPlace src/colab_cli/auto_update.py \
      --replace-fail 'return f"pip install --upgrade {PYPI_PACKAGE_NAME}"' \
                     'return "nix-aura /packages-update"' \
      --replace-fail "typer.echo(f\"[colab] Running: {' '.join(cmd)}\")" \
                     'raise SystemExit("[colab] Managed by Nix; update it through nix-aura instead.")'
  '';

  doCheck = false;

  meta = with lib; {
    description = "CLI for interacting with Google Colab";
    homepage = "https://github.com/googlecolab/google-colab-cli";
    license = licenses.asl20;
    mainProgram = "colab";
  };
}

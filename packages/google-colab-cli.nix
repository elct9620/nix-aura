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

  # Google's fork of datalayer/jupyter-kernel-client, pinned by the CLI's
  # uv.lock; not interchangeable with the PyPI release.
  jupyter-kernel-client = python3Packages.buildPythonPackage rec {
    pname = "jupyter-kernel-client";
    version = "0.8.0";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "googlecolab";
      repo = "jupyter-kernel-client";
      rev = "f18e982c3265df5e923aa9def101ab3fd737e139";
      sha256 = "sha256-A2c78qPdY5HIdAmcr1PP3UbtMty84zrNnvZItu7Rk+E=";
    };

    build-system = with python3Packages; [ hatchling ];

    dependencies = with python3Packages; [
      jupyter-client
      jupyter-core
      jupyter-mimetypes
      requests
      traitlets
      typing-extensions
      websocket-client
    ];

    doCheck = false;

    meta = with lib; {
      description = "Jupyter Kernel Client through HTTP and WebSocket (Colab fork)";
      homepage = "https://github.com/googlecolab/jupyter-kernel-client";
      license = licenses.bsd3;
    };
  };
in
python3Packages.buildPythonApplication rec {
  pname = "google-colab-cli";
  version = "0.5.9";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "googlecolab";
    repo = "google-colab-cli";
    rev = "v${version}";
    # NOTE: Calculate sha256
    # make google-colab-cli
    sha256 = "sha256-oRhAKWeZe+faRuXVKYNLnLeFDaVCFkeAO+utz+/t/Xw=";
  };

  build-system = with python3Packages; [
    hatchling
    hatch-vcs
  ];

  dependencies = with python3Packages; [
    click
    google-auth
    google-auth-oauthlib
    jupyter-kernel-client
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
    "google-auth"
    "google-auth-oauthlib"
    "pydantic"
    "rich"
    "typer"
  ];

  doCheck = false;

  meta = with lib; {
    description = "CLI for interacting with Google Colab";
    homepage = "https://github.com/googlecolab/google-colab-cli";
    license = licenses.asl20;
    mainProgram = "colab";
  };
}

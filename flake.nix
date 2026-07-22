{
  description = "The nix-based universal development environment";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # Consumed as-is: upstream's flake handles the OpenCC dictionary source and
    # Python codegen. Intentionally not following our nixpkgs to keep that
    # build reproducible against the pin upstream tests.
    zhtw-mcp.url = "github:sysprog21/zhtw-mcp";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, flake-utils, zhtw-mcp }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays =
          [ (final: prev: { zhtw-mcp = zhtw-mcp.packages.${system}.default; }) ] ++
          map
            (name: import (./overlays + "/${name}"))
            (builtins.attrNames (builtins.readDir ./overlays));

        pkgs-unstable = import nixpkgs-unstable {
          inherit system;
          inherit overlays;

          config.allowUnfree = true;
        };

        pkgs = import nixpkgs {
          inherit system;
          inherit overlays;

          unstable = pkgs-unstable;

          config.allowUnfree = true;
        };
      in {
        packages = {
          ruby-build = pkgs.ruby-build;
          leaf = pkgs.leaf;
          agent-browser = pkgs.agent-browser;
          google-colab-cli = pkgs.google-colab-cli;
          zhtw-mcp = pkgs.zhtw-mcp;
          default = pkgs.buildEnv {
            name = "aura";
            paths = [
              pkgs-unstable.auraLatestUnstable
              pkgs.auraFull
            ];
          };
        };

        devShells.default = import ./shell.nix { inherit pkgs; };
      }
    ) // {
      templates = {
        ruby = {
          path = ./templates/ruby;
          description = "A simple ruby development environment";
        };

        go = {
          path = ./templates/go;
          description = "A simple go development environment";
        };

        default = self.templates.ruby;
      };
    };
}

{
  description = "The nix-based universal development environment";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-25.11-darwin";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays =
          [] ++
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

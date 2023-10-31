{
  description = "The nix-based universal development environment";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays =
          [] ++
          map
            (name: import (./overlays + "/${name}"))
            (builtins.attrNames (builtins.readDir ./overlays));

        pkgs = import nixpkgs {
          inherit system;
          inherit overlays;

          config.allowUnfree = true;
        };
      in {
        packages = {
          inherit pkgs;
          ruby-build = pkgs.ruby-build;
          default = pkgs.auraFull;
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

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
        };
      in {
        packages = {
          inherit pkgs;
          default = pkgs.auraFull;
        };

        templates = {
          ruby = {
            path = ./templates/ruby;
            description = "A simple ruby development environment";
          };

          default = self.templates.ruby;
        };

        devShells.default = import ./shell.nix { inherit pkgs; };
      }
    );
}

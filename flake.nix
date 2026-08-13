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
      # Deprecated. These pin nixos-22.11, which is long past end of life, and
      # the toolchains they install are several major versions behind. They stay
      # published only so existing references keep resolving; devbox covers this
      # ground now, and one-off needs are better served by a project-local flake.
      templates =
        let
          deprecated = ''
            # Deprecated

            This template is no longer maintained: it pins nixos-22.11, which no
            longer receives updates. Use devbox, or write a project-local flake
            against a current nixpkgs, instead.
          '';
        in
        {
          ruby = {
            path = ./templates/ruby;
            description = "Deprecated: a simple ruby development environment";
            welcomeText = deprecated;
          };

          go = {
            path = ./templates/go;
            description = "Deprecated: a simple go development environment";
            welcomeText = deprecated;
          };

          default = self.templates.ruby;
        };
    };
}

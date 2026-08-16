{
  description = "The nix-based universal development environment";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # Intentionally not following our nixpkgs, to keep upstream's build
    # reproducible against the pin it tests.
    zhtw-mcp.url = "github:sysprog21/zhtw-mcp";
    # Must match OPENCC_COMMIT in upstream's scripts/gen-s2t-tables.py; pinned
    # in the URL so `nix flake update` cannot move the conversion tables.
    opencc-src = {
      url = "github:BYVoid/OpenCC/5249273a3e5606852f088c9a8b23522145d94f78";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, flake-utils, zhtw-mcp, opencc-src }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # Upstream's generator reads the OpenCC dictionaries from a cache
        # directory keyed by the commit it pins, but upstream's flake still
        # seeds the older flat path. The generator therefore finds nothing and
        # falls through to a download the build sandbox cannot serve. Seed the
        # keyed path, and fail loudly rather than silently if the generator's
        # pin ever diverges from ours.
        #
        # Drop this override once sysprog21/zhtw-mcp#108 lands upstream.
        zhtw-mcp-pkg = zhtw-mcp.packages.${system}.default.overrideAttrs (_: {
          preBuild = ''
            pinned=$(sed -n 's/^OPENCC_COMMIT = "\(.*\)"$/\1/p' scripts/gen-s2t-tables.py)
            if [ "$pinned" != "${opencc-src.rev}" ]; then
              echo "error: opencc-src pins ${opencc-src.rev}, but" >&2
              echo "  scripts/gen-s2t-tables.py pins $pinned." >&2
              echo "  Re-pin inputs.opencc-src.url in flake.nix to $pinned." >&2
              exit 1
            fi

            cache=data/opencc/''${pinned:0:12}
            mkdir -p "$cache"
            for dict in STPhrases STCharacters TWVariants; do
              cp ${opencc-src}/data/dictionary/$dict.txt "$cache/$dict.txt"
            done

            python3 scripts/gen-s2t-tables.py
            rustfmt src/engine/s2t_data.rs
          '';
        });

        overlays =
          [ (final: prev: { zhtw-mcp = zhtw-mcp-pkg; }) ] ++
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
          spinel = pkgs.spinel;
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

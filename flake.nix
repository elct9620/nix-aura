{
  description = "The nix-based universal development environment";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    {
      overlays = import ./overlays;
    }
    //
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs {
        inherit system;

        overlays = [ self.overlays ];
      };
      in {
        packages.default = pkgs.aura;
        devShells.default = import ./shell.nix { inherit pkgs; };
      }
    );
}

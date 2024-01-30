update:
	nix flake update

bundle:
	brew bundle

ruby-build:
	@read -p "Revision: " REVISION; \
	nix-shell -p nix-prefetch-git jq --run "nix hash to-sri sha256:\$$(nix-prefetch-git --url https://github.com/rbenv/ruby-build --quiet --rev $$REVISION | jq -r '.sha256')"

update:
	nix flake update

bundle:
	brew bundle

ruby-build:
	@read -p "Revision: " REVISION; \
	nix-shell -p nix-prefetch-github jq --run "echo \$$(nix-prefetch-github rbenv ruby-build --quiet --rev $$REVISION | jq -r '.hash')"

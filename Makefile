update:
	nix flake update

bundle:
	brew bundle

ruby-build:
	@read -p "Revision: " REVISION; \
	echo "Fetching ruby-build at revision $$REVISION"; \
	nix-shell -p nix-prefetch-github jq --run "echo \$$(nix-prefetch-github rbenv ruby-build --quiet --rev $$REVISION | jq -r '.hash')"

push:
	devbox global push git@github.com:elct9620/devbox.git

pull:
	devbox global pull git@github.com:elct9620/devbox.git

gc:
	nix-store --gc

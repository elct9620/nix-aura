Nix Aura
===

## Requirement

Install "Nix"

```bash
sh <(curl -L https://nixos.org/nix/install) --daemon
```

Add below lines in `~/.config/nix/nix.conf` to enable Nix Flake

```bash
experimental-features = nix-command flakes
keep-derivations = true
keep-outputs = true
```

## Install

```bash
nix profile install github:elct9620/nix-aura
```

Link `.bashrc` and `.zshrc`

```bash
ln -s $HOME/.nix-profile/etc/bashrc ~/.bashrc
ln -s $HOME/.nix-profile/etc/zshrc ~/.zshrc
```

> If the `.bashrc` or `.zshrc` already exists, you can use `source $HOME/.nix-profile/etc/bashrc` to load it.

## Setup Nix for Project

The template include `direnv` config and you can use `direnv allow .` to make environment autolaod.

### Ruby

```bash
nix flake init --template github:elct9620/nix-aura#ruby
# Or aura-init
aura-init ruby
```

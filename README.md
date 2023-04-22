Nix Aura
===

## Configuration

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

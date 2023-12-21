Nix Aura
===

## Requirement

* Nix
* [NerdFonts](https://github.com/ryanoasis/nerd-fonts/tree/master)
    * I use JetBrians Mono with Ligature

## Install

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

Enable `nix profile` for default environment

```bash
nix profile install github:elct9620/nix-aura
```

Link `.bashrc` and `.zshrc`

```bash
ln -s $HOME/.nix-profile/etc/bashrc ~/.bashrc
ln -s $HOME/.nix-profile/etc/zshrc ~/.zshrc
```

> If the `.bashrc` or `.zshrc` already exists, you can use `source $HOME/.nix-profile/etc/bashrc` to load it.

## Upgrade

Find installed profile

```bash
$ nix profile list

Index:              0
Flake attribute:    packages.x86_64-darwin.default
Original flake URL: git+file:///Users/elct9620/Workspace/nix/nix-aura
Locked flake URL:   git+file:///Users/elct9620/Workspace/nix/nix-aura
Store paths:        /nix/store/nm5bl6w9dqn9m6wvghdgbxpsjsw299b9-aura-full
```

Upgrade profile via specify index

```bash
nix profile upgrade 0
```

## Usage

### vim

The `vim` is design to use [elct9620-vim](https://github.com/elct9620/elct9620-vim) with Plug, please clone it into `~/.vim` before use the command.

### rbenv

The Nix is useful for installing tools but does not provide a good experience for developers.

To manage the Ruby development environment, the rbenv is still a better option for hosting each Ruby version standalone.

> Limitation: Nix didn't provide the `pc` file for pkg-config therefore we still need to manual provide dependency for installing ruby
>
> WIP: make `pc` file available for ruby-build or provide them via Homebrew

#### Requirements

Install `libyaml` to ensure `psych` work correctly

```bash
brew install libyaml
```

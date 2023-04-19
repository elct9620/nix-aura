{ pkgs ? import <nixpkgs> { } }:
with pkgs;

mkShell {
  packages = [
    git
    tmux
    vim
    coreutils
  ];
}

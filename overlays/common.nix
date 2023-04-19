{ super }:
with super;
super.buildEnv {
  name = "aura-common";
  paths = [
    bat
    coreutils
    git
    htop
    tmux
    zsh
  ];
}

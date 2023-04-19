{ super }:
with super;
super.buildEnv {
  name = "aura-common";
  paths = [
    git
    tmux
    zsh
    bat
  ];
}

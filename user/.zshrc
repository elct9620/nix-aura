POWERLINE_MODUES="venv,user,ssh,cwd,perms,git,jobs,exit,root,direnv,nix-shell"

function powerline_precmd() {
    PS1="$($HOME/.nix-profile/bin/powerline-go -error $? -jobs ${${(%):%j}:-0} -modules $POWERLINE_MODUES -cwd-mode dironly)"
}

function install_powerline_precmd() {
  for s in "${precmd_functions[@]}"; do
    if [ "$s" = "powerline_precmd" ]; then
      return
    fi
  done
  precmd_functions+=(powerline_precmd)
}

if [ "$TERM" != "linux" ] && [ -f "$HOME/.nix-profile/bin/powerline-go" ]; then
    install_powerline_precmd
fi

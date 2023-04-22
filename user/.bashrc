POWERLINE_MODUES="venv,user,ssh,cwd,perms,git,jobs,exit,root,direnv,nix-shell"
POWERLINE_OPTIONS="-cwd-mode dironly"

function _update_ps1() {
    PS1="$($HOME/.nix-profile/bin/powerline-go -jobs $(jobs -p | wc -l) -modules $POWERLINE_MODUES $POWERLINE_OPTIONS)"
}

if [ "$TERM" != "linux" ] && [ -f "$HOME/.nix-profile/bin/powerline-go" ]; then
    PROMPT_COMMAND="_update_ps1; $PROMPT_COMMAND"
fi

# Nix
[ -f $HOME/.nix-profile/share/nix-direnv/direnvrc ] && source $HOME/.nix-profile/share/nix-direnv/direnvrc
[ -f $HOME/.nix-profile/bin/direnv ] && eval "$(direnv hook bash)"

POWERLINE_MODUES="venv,user,ssh,cwd,perms,git,jobs,exit,root,direnv,nix-shell"
POWERLINE_OPTIONS="-cwd-mode dironly"

function _update_ps1() {
    PS1="$($HOME/.nix-profile/bin/powerline-go -error $? -jobs $(jobs -p | wc -l) -modules $POWERLINE_MODUES $POWERLINE_OPTIONS)"
}

if [ "$TERM" != "linux" ] && [ -f "$HOME/.nix-profile/bin/powerline-go" ]; then
    PROMPT_COMMAND="_update_ps1; $PROMPT_COMMAND"
fi

self: super:
with super;
let
  wrappedTmux = writeShellScriptBin "tmux" ''
    TMUX_CONFIG="-f ${../config/tmux.conf}"
    test -f ~/.tmux.conf && TMUX_CONFIG="$TMUX_CONFIG -f $HOME/.tmux.conf"
    exec "${tmux}/bin/tmux" $TMUX_CONFIG "$@"
  '';
in
{

  tmuxWithConfig = symlinkJoin {
    name = "tmuxWithConfig";
    buildInputs = [ makeWrapper ];
    paths = [
      wrappedTmux
      tmux
    ];
  };
}

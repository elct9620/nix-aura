self: super:
with super;
{
  tmuxWithConfig = buildEnv {
    name = "tmuxWithConfig";
    buildInputs = [ makeWrapper ];
    paths = [ zsh ];
    postBuild = ''
        unlink "$out/bin"
        mkdir -p "$out/bin"
        for path in "${self.tmux}"/bin/*; do
          bin=$(basename "$path")
          makeWrapper "$path" "$out/bin/$bin" --add-flags "-f ${../config/tmux.conf}"
        done
      '';
  };
}

self: super:
with super;
{
  visidataWithTheme = symlinkJoin {
    name = "visidataWithTheme";
    paths = [ visidata ];
    nativeBuildInputs = [ makeWrapper ];
    postBuild = ''
      for bin in vd visidata; do
        wrapProgram "$out/bin/$bin" \
          --prefix PYTHONPATH : ${../config/visidata} \
          --add-flags "--imports 'plugins aura_theme'"
      done
    '';
  };
}

self: super:
with super;
{
  auraFull = buildEnv {
    name = "aura-full";
    paths = [
      auraCommon
      auraPid
      auraRuby
      auraGo
      auraNode
      auraTemplateCmd
    ];
  };
}

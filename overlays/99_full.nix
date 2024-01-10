self: super:
with super;
{
  auraFull = buildEnv {
    name = "aura-full";
    paths = [
      auraCommon
      auraCloud
      auraPid
      auraRuby
      auraGo
      auraNode
      auraRust
      auraTemplateCmd
    ];
  };
}

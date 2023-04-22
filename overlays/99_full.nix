self: super:
with super;
{
  auraFull = buildEnv {
    name = "aura-full";
    paths = [
      auraCommon
      auraRuby
      auraGo
      auraNode
      auraTemplateCmd
    ];
  };
}

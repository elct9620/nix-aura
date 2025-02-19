self: super:
with super;
{
  auraFull = buildEnv {
    name = "aura-full";
    paths = [
      auraCommon
      auraCloud
      auraAssistant
      auraPid
      auraRuby
      auraGo
      auraNode
      auraRust
      auraJava
      auraTemplateCmd
    ];
  };
}

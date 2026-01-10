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
      auraPython
      auraGo
      auraNode
      auraRust
      auraJava
      auraTemplateCmd
    ];
  };
}

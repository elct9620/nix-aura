self: super:
with super;
{
  auraFull = buildEnv {
    name = "aura-full";
    paths = [
      auraCommon
      auraDev
      auraCloud
      auraPid
      auraRuby
      auraPython
      auraGo
      auraNode
      auraRust
      auraJava
      auraGodot
      auraTemplateCmd
    ];
  };
}

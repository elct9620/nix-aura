self: super:
with super;
{
  auraJava = buildEnv {
    name = "aura-java";
    paths = [
      jdk17
    ];
  };
}

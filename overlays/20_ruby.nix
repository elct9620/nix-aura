self: super:
with super;
{
  auraRuby = buildEnv {
    name = "aura-ruby";
    paths = [
      ruby_3_2
    ];
  };
}

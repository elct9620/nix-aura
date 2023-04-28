self: super:
with super;
{
  auraRuby = buildEnv {
    name = "aura-ruby";
    paths = [
      rbenv
      ruby-build
    ];
  };
}

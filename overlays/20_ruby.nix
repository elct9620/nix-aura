self: super:
with super;
{
  auraRuby = buildEnv {
    name = "aura-ruby";
    paths = [
      rbenv
      ruby-build
      pkg-config
      libyaml
      readline
      gmp
    ];
  };
}

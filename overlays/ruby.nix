{ super }:
with super;
super.buildEnv {
  name = "aura-ruby";
  paths = [
    ruby_3_2
  ];
}

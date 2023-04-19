{ super }:
with super;
super.buildEnv {
  name = "aura-node";
  paths = [
    nodejs
    yarn
  ];
}

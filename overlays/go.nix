{ super }:
with super;
super.buildEnv {
  name = "aura-go";
  paths = [
    go
    gopls
  ];
}

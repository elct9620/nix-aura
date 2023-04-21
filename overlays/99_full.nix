self: super:
with super;
{
  auraGo = buildEnv {
    name = "aura-go";
    paths = [
      go
      gopls
    ];
  };
}

self: super:
with super;
{
  auraNode = buildEnv {
    name = "aura-node";
    paths = [
      nodejs_22
      yarn
      pnpm
    ];
  };
}

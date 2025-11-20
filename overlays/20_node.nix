self: super:
with super;
{
  auraNode = buildEnv {
    name = "aura-node";
    paths = [
      nodejs_24
      bun
      yarn
      pnpm
    ];
  };
}

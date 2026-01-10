self: super:
with super;
{
  auraPython = buildEnv {
    name = "aura-python";
    paths = [
      pyright
    ];
  };
}

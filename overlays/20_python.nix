self: super:
with super;
{
  auraPython = buildEnv {
    name = "aura-python";
    paths = [
      python3
      uv
      pyright
    ];
  };
}

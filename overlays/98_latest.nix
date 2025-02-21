self: super:
with super;
{
  auraLatestUnstable = buildEnv {
    name = "aura-latest";
    paths = [
      auraAssistant
    ];
  };
}

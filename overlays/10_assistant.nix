self: super:
with super;
{
  auraAssistant = buildEnv {
    name = "aura-assistant";
    paths = [
      agent-browser
      google-colab-cli
    ];
 };
}

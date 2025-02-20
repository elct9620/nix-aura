self: super:
with super;
{
  auraAssistant = buildEnv {
    name = "aura-assistant";
    paths = [
      aider-chat.withPlaywright
      playwright
    ];
 };
}

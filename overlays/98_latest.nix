self: super:
with super;
{
  auraLatestUnstable = buildEnv {
    name = "aura-latest";
    paths = [
      auraAssistant
      # Unstable
      pi-coding-agent
      # Use Latest Version
      terraform
      duckdb
      # AWS SAM CLI usually broken in stable nixpkgs
      aws-sam-cli
    ];
  };
}

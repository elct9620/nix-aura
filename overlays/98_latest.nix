self: super:
with super;
{
  auraLatestUnstable = buildEnv {
    name = "aura-latest";
    paths = [
      auraAssistant
      # Use Latest Version
      terraform
      duckdb
      # AWS SAM CLI usually broken in stable nixpkgs
      aws-sam-cli
    ];
  };
}

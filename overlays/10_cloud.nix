self: super:
with super;
{
  auraCloud = buildEnv {
    name = "aura-cloud";
    paths = [
      awscli2
      ssm-session-manager-plugin
      aws-sam-cli
      kustomize
      # S3
      minio-client
    ];
 };
}

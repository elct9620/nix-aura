self: super:
with super;
{
  auraCloud = buildEnv {
    name = "aura-cloud";
    paths = [
      awscli2
      ssm-session-manager-plugin
      aws-sam-cli
      # Kubernetes
      kustomize
      kubernetes-helm
      # S3
      minio-client
    ];
 };
}

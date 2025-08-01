self: super:
with super;
{
  auraCloud = buildEnv {
    name = "aura-cloud";
    paths = [
      awscli2
      ssm-session-manager-plugin
      aws-sam-cli
      okta-aws-cli
      # Kubernetes
      kustomize
      kubernetes-helm
      kubeseal
      kn
      func
      # S3
      minio-client
    ];
 };
}

self: super:
with super;
{
  auraCloud = buildEnv {
    name = "aura-cloud";
    paths = [
      awscli2
      ssm-session-manager-plugin
      (aws-sam-cli.override {
        python3 = python311;
      })
      okta-aws-cli
      # Kubernetes
      kustomize
      kubernetes-helm
      kubeseal
      # S3
      minio-client
    ];
 };
}

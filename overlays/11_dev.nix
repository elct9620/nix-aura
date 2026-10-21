self: super:
with super;
{
  auraDev = buildEnv {
    name = "aura-dev";
    paths = [
      allure
      pkg-config
      git
      git-lfs
      delta # The better diff tool can used by git
      upx
      protobuf
      cz-cli
      dive
      cmake
      shellcheck
      bats
      sumitsubo # Spec-versus-code linter
      hugo
      # Development Dependencies
      imagemagick
      # Work
      jira-cli-go
      gh
      glab
    ];
 };
}

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
      gitleaks # Secret scanner
      sumitsubo # Spec-versus-code linter
      hugo
      # Development Dependencies
      imagemagick
      android-tools # adb/fastboot for Android device debugging
      # Work
      jira-cli-go
      gh
      glab
    ];
 };
}

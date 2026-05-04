self: super:
with super;
{
  auraConfig = stdenv.mkDerivation {
    name = "aura-config";
    src = ../etc;
    installPhase = ''
      mkdir -p $out/etc
      cp -r . $out/etc
    '';
  };

  auraCommon = buildEnv {
    name = "aura-common";
    paths = [
      self.auraConfig
      # Text
      glow
      batWithAlias
      silver-searcher
      ripgrep
      vale # Writing linter
      # Editor
      vimWithConfig
      # Shell
      coreutils
      tmuxWithConfig
      powerline-go
      zsh-autosuggestions
      zsh-completions
      # Development
      allure
      pkg-config
      git
      git-lfs
      delta # The better diff tool can used by git
      cloudflared
      vault
      upx
      protobuf
      cz-cli
      dive
      cmake
      shellcheck
      bats
      # Development Dependencies
      imagemagick
      # Tools
      wget
      hugo
      jq
      yq-go
      cloc
      tailspin
      dive
      mtr
      rclone
      poppler-utils
      # System
      htop
      tree
      reattach-to-user-namespace
      # Work
      jira-cli-go
      gh
      glab
      # Utils
      inetutils
      ffmpeg
      # Nix
      direnv
      nix-direnv
    ];
 };
}

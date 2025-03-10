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
      batWithAlias
      silver-searcher
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
      cloudflared
      vault
      upx
      protobuf
      cz-cli
      dive
      # Development Dependencies
      imagemagick
      # Tools
      wget
      hugo
      jq
      cloc
      tailspin
      dive
      mtr
      # System
      htop
      tree
      reattach-to-user-namespace
      # Work
      jira-cli-go
      # Utils
      inetutils
      ffmpeg
      # Nix
      direnv
      nix-direnv
    ];
 };
}

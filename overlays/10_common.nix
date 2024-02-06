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
      terraform
      vault
      upx
      # Tools
      wget
      hugo
      jq
      # System
      htop
      tree
      reattach-to-user-namespace
      # Utils
      inetutils
      # Nix
      direnv
      nix-direnv
    ];
 };
}

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
      leaf
      batWithAlias
      silver-searcher
      fd
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
      # Tools
      wget
      jq
      yq-go
      visidataWithTheme # Tabular data explorer
      cloc
      tailspin
      mtr
      rclone
      poppler-utils
      defuddle
      # System
      htop
      tree
      reattach-to-user-namespace
      # Utils
      inetutils
      ffmpeg
      # Nix
      direnv
      nix-direnv
    ];
 };
}

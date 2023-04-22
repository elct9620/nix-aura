self: super:
with super;
{
 auraCommon = buildEnv {
   name = "aura-common";
   paths = [
     # Text
     batWithAlias
     # Editor
     vimWithConfig
     # Shell
     coreutils
     tmuxWithConfig
     powerline-go
     zsh-autosuggestions
     # Development
     git
     # System
     htop
     reattach-to-user-namespace
     # Nix
     direnv
     nix-direnv
   ];
 };
}

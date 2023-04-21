self: super:
with super;
{
 auraCommon = buildEnv {
   name = "aura-common";
   paths = [
     bat
     coreutils
     git
     htop
     reattach-to-user-namespace
     tmuxWithConfig
     vimWithConfig
     zsh
   ];
 };
}

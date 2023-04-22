self: super:
with super;
{
 auraCommon = buildEnv {
   name = "aura-common";
   paths = [
     # Text
     bat
     # Editor
     vimWithConfig
     # Shell
     coreutils
     tmuxWithConfig
     powerline-go
     # Development
     git
     # System
     htop
     reattach-to-user-namespace
   ];
 };
}

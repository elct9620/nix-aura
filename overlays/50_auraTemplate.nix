self: super:
with super;
{

  auraTemplateCmd = writeShellScriptBin "aura-init" ''
    exec "nix" flake init --template github:elct9620/nix-aura#$@
  '';
}

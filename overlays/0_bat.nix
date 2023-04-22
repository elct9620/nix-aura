self: super:
with super;
{
  batWithAlias = writeShellScriptBin "cat" ''
    exec "${bat}/bin/bat" "$@"
  '';
}

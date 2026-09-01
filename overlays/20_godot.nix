self: super:
with super;
{
  auraGodot = buildEnv {
    name = "aura-godot";
    paths = [
      # Pinned to the 4.7 line: a Godot project is only compatible with the
      # minor version it was authored in, so the editor must not float with
      # nixpkgs the way the unversioned `godot` alias does.
      godot_4_7
      # gdformat/gdlint, the de facto GDScript toolchain outside the editor
      gdtoolkit_4
    ];
  };
}

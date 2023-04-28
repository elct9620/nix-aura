self: super:
with super;
{
  auraPid = callPackage ../packages/aura-pid.nix { };
  ruby-build = callPackage ../packages/ruby-build.nix { };
}

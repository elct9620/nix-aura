self: super:
with super;
{
  auraPid = callPackage ../packages/aura-pid.nix { };
  ruby-build = callPackage ../packages/ruby-build.nix { };
  leaf = callPackage ../packages/leaf.nix { };
  agent-browser = callPackage ../packages/agent-browser.nix { };
}

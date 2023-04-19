self: super:
with super;
{
  auraCommon = import ./common.nix { inherit super; };
  auraRuby = import ./ruby.nix { inherit super; };
  auraGo = import ./go.nix { inherit super; };
  auraNode = import ./node.nix { inherit super; };

  aura = with self; buildEnv {
    name = "aura-full";
    paths = [
      auraCommon
      auraRuby
      auraGo
      auraNode
    ];
  };
}

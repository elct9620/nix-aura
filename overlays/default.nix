self: super:
with super;
{
  common = import ./common.nix { inherit super; };

  aura = with self; buildEnv {
    name = "nix-aura";
    paths = [
      common
    ];
  };
}

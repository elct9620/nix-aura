self: super:
with super;
{
  auraRust = with self; buildEnv {
    name = "aura-rust";
    paths = [
      rustc
      cargo
      rustfmt
      clippy
      rust-analyzer
    ];
  };
}

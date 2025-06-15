self: super:
with super;
{
  auraRust = with self; buildEnv {
    name = "aura-rust";
    paths = [
      # Use `rustup` to manage Rust toolchains, e.g. cargo, rustc, etc.
      rustup
    ];
  };
}

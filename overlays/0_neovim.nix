self: super:
with super;
let
  config = ../config/nvim;
  # obsidian.nvim from unstable: native LSP completion and CJK tags arrived after
  # the stable pin. Falls back to self where `unstable` is not provided.
  obsidian-nvim = (self.unstable or self).vimPlugins.obsidian-nvim;
in
{
  # Plugins come from nixpkgs so flake.lock pins them; config/nvim is put on
  # the runtimepath so plugin/*.lua is sourced like a regular config dir.
  neovimWithConfig = wrapNeovim neovim-unwrapped {
    configure = {
      customLuaRC = ''
        vim.opt.runtimepath:prepend("${config}")
        dofile("${config}/init.lua")
      '';
      packages.aura.start = with vimPlugins; [
        (nvim-treesitter.withPlugins (p: with p; [
          bash
          c
          hcl
          json
          markdown
          markdown_inline
          ruby
          terraform
          toml
          yaml
        ]))
        nvim-lspconfig
        obsidian-nvim
        mini-pick
        vim-tmux-navigator
        vim-wakatime
      ];
    };
    # Only tools the editor alone needs; shared CLIs (ripgrep) live in auraCommon.
    extraMakeWrapperArgs = "--prefix PATH : ${lib.makeBinPath [ copilot-language-server ]}";
  };
}

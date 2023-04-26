self: super:
with super;
{
  vim-full = vim-full.override {
    guiSupport = false;
    darwinSupport = true;
  };

  vimWithConfig = buildEnv {
    name = "vimWithConfig";
    paths = [
      (self.vim-full.customize {
        vimrcConfig.customRC = builtins.readFile ../config/vimrc;
      })
    ];
  };
}

self: super:
with super;
{
  vim.python = true;

  vimWithConfig = buildEnv {
    name = "vimWithConfig";
    paths = [
      (vim-full.customize {
        vimrcConfig.customRC = ''
        " Install vim-plug if we don't already have it
        if empty(glob("$HOME/.vim/autoload/plug.vim"))
            " Ensure all needed directories exist  (Thanks @kapadiamush)
            execute '!mkdir -p ~/.vim/plugged'
            execute '!mkdir -p ~/.vim/autoload'
            " Download the actual plugin manager
            execute '!curl -fLo ~/.vim/autoload/plug.vim https://raw.github.com/junegunn/vim-plug/master/plug.vim'
        endif

        " Load Plug
        call plug#begin('~/.vim/plugged')
        source $HOME/.vim/Plug
        filetype plugin indent on
        call plug#end()
        '';
      })
    ];
  };
}

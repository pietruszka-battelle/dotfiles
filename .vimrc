
call plug#begin()
" Automatically executes `filetype plugin indent on` and `syntax enable`.
Plug 'https://github.com/vim-airline/vim-airline.git'
Plug 'https://github.com/tpope/vim-commentary.git'
Plug 'https://github.com/hashivim/vim-terraform.git'
Plug 'https://github.com/preservim/nerdtree.git'
call plug#end()
" You can revert the settings after the call like so:
"   filetype indent off   " Disable file-type-specific indentation
"   syntax off            " Disable syntax

" For nerdtree
nnoremap <leader>n :NERDTreeFocus<CR>
nnoremap <C-n> :NERDTree<CR>
nnoremap <C-t> :NERDTreeToggle<CR>
nnoremap <C-f> :NERDTreeFind<CR>

augroup myCmds
au!
autocmd VimEnter * silent !echo -ne "\e[5 q"
augroup END

set laststatus=2

set number
set expandtab

set tabstop=4
set softtabstop=4
set shiftwidth=4

set ignorecase
set smartcase

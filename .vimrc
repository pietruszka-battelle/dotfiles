call plug#begin()
" Automatically executes `filetype plugin indent on` and `syntax enable`.
Plug 'https://github.com/vim-airline/vim-airline.git'
Plug 'https://github.com/tpope/vim-commentary.git'
Plug 'https://github.com/ctrlpvim/ctrlp.vim.git'
Plug 'https://github.com/vim-scripts/CtrlP-SmartTabs.git'
call plug#end()
" You can revert the settings after the call like so:
"   filetype indent off   " Disable file-type-specific indentation
"   syntax off            " Disable syntax
let mapleader = " "
let g:ctrlp_extensions = ['smarttabs']
let g:ctrlp_smarttabs_modify_tabline = 1
let g:ctrlp_smarttabs_reverse = 1

nnoremap <leader>p :CtrlPSmartTabs<CR>
nnoremap <leader>o o<esc>
nnoremap <leader>O O<esc>

set number
set expandtab
set tabline=2

set tabstop=4
set softtabstop=4
set shiftwidth=4

set ignorecase
set smartcase

" whothis managed vimrc

" basic features
set nocompatible

" language specific features
syntax on
filetype plugin indent on

" show line numbers
set number
set relativenumber

" indentation behavior
set expandtab
set tabstop=4
set shiftwidth=4
set autoindent
set smartindent

" search and highlighting
set incsearch
set hlsearch
set ignorecase
set smartcase

" completion
set wildmenu
set wildmode=list:longest

" editing behavior
set backspace=indent,eol,start

" visual/ui
set cursorline
set colorcolumn=80
set scrolloff=8
set sidescrolloff=8
set signalcolumn=auto
set showcmd
set title

" files/buffers
set hidden
set autoread
set undofile
set undodir=~/.vim/undodir

" whitespace visibility
set list
set listchars=tab:→,trail:·,nbsp:␣

set nocompatible
syntax on
filetype plugin indent on

set encoding=utf-8
set number
set ruler
set showcmd
set laststatus=2
set wildmenu
set wildmode=longest:full,full
set scrolloff=3

set incsearch
set hlsearch
set ignorecase
set smartcase

set expandtab
set tabstop=2
set shiftwidth=2
set softtabstop=2
set autoindent
set smartindent

set backspace=indent,eol,start
set hidden
set mouse=a
set ttyfast
set lazyredraw

" Use system clipboard when available.
if has('clipboard')
  if has('unnamedplus')
    set clipboard=unnamedplus
  else
    set clipboard=unnamed
  endif
endif

" Put swap/backup/undo under ~/.vim so the working tree stays clean.
set directory=~/.vim/swap//
set backupdir=~/.vim/backup//
set undodir=~/.vim/undo//
set undofile
silent! call mkdir(expand('~/.vim/swap'),   'p')
silent! call mkdir(expand('~/.vim/backup'), 'p')
silent! call mkdir(expand('~/.vim/undo'),   'p')

let mapleader = ' '
nnoremap <leader><space> :nohlsearch<CR>
nnoremap <leader>w :w<CR>

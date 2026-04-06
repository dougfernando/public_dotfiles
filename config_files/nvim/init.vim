set nocompatible

call plug#begin()
    Plug 'ellisonleao/glow.nvim'
    Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
    Plug 'junegunn/fzf.vim'
    Plug 'ryanoasis/vim-devicons'
    Plug 'catppuccin/nvim', { 'as': 'catppuccin' }
    Plug 'nvim-tree/nvim-tree.lua'
    Plug 'nvim-tree/nvim-web-devicons'

call plug#end()

set number
set relativenumber
set clipboard+=unnamedplus
set cursorline
set autoindent
set expandtab
set smartindent
set tabstop=4
set shiftwidth=4
set title
set hlsearch
set incsearch
set smartcase
set spell
set noswapfile
set mouse=a
set splitbelow splitright
set nobackup nowritebackup

colorscheme catppuccin-frappe

highlight Normal ctermbg=NONE guibg=NONE
highlight NonText ctermbg=NONE guibg=NONE
highlight LineNr ctermbg=NONE guibg=NONE
" optionally clear other groups used by your colorscheme:
highlight SignColumn ctermbg=NONE guibg=NONE
highlight VertSplit ctermbg=NONE guibg=NONE

filetype plugin on
syntax on

" Completion and suggestions
set completeopt=menuone,noinsert,noselect " Configure completion menu
set shortmess+=c                " Avoid extra messages during completion

" remaps
nnoremap <expr> j v:count ? 'j' : 'gj'
nnoremap <expr> k v:count ? 'k' : 'gk'


let mapleader = ","

nnoremap <leader>w :w!<CR>
nnoremap <leader>* :%s/\*\*//g<CR>

nnoremap <leader>e :NvimTreeToggle<CR>
nnoremap <leader>t :NvimTreeFocus<CR>
nnoremap <leader>f :NvimTreeFindFile<CR>

nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

:imap kj <Esc>

nnoremap <leader>s :vsplit<CR>
nnoremap <leader>p :set spelllang=pt<CR>


" Define an autocommand group
augroup vim_enter_group
  autocmd!
" Set the directory to the Desktop on VimEnter
  autocmd VimEnter * cd $HOME
augroup END

lua << EOF
-- disable netrw at the very start of your init.lua (strongly recommended)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- set termguicolors to enable highlight groups
vim.opt.termguicolors = true

-- empty setup with defaults
require("nvim-tree").setup()
EOF

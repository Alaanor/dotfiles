" vim config
" ----------

" generic
syntax on
set relativenumber
set hlsearch
set cursorline
set clipboard=unnamedplus

" tab
set tabstop=2
set shiftwidth=2
set softtabstop=2
set expandtab
set autoindent

" plugin
" ------

call plug#begin('~/.vim/plugged')

    Plug 'morhetz/gruvbox'
    Plug 'scrooloose/nerdtree'
		Plug 'ryanoasis/vim-devicons'
    Plug 'tpope/vim-fugitive'
    Plug 'autozimu/LanguageClient-neovim', {
        \ 'branch': 'next',
        \ 'do': 'bash install.sh',
        \ }
    Plug 'rust-lang/rust.vim'
    Plug 'scrooloose/syntastic'
    Plug 'majutsushi/tagbar'
    Plug 'prabirshrestha/vim-lsp'
    Plug 'mattn/vim-lsp-settings'
    Plug 'prabirshrestha/asyncomplete.vim'
    Plug 'prabirshrestha/asyncomplete-lsp.vim'
    Plug 'jiangmiao/auto-pairs'
    Plug 'unblevable/quick-scope'
    Plug 'chrisbra/sudoedit.vim'
    Plug 'tpope/vim-surround'
    Plug 'mboughaba/i3config.vim' 
    Plug 'elkowar/yuck.vim'

call plug#end()

" plugin configuration
" --------------------

" gruvbox
" -------
autocmd vimenter * colorscheme gruvbox

" nerd-tree
" ---------

" open it if no file
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif

" open when opeing a directory
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists("s:std_in") | exe 'NERDTree' argv()[0] | wincmd p | ene | exe 'cd '.argv()[0] | endif

" close vim if the last panel is nerdtree
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

" keybinding
map <C-n> :NERDTreeToggle<CR>

" tagbar
nmap <C-t> :TagbarToggle<CR>

" rust
let g:rustfmt_autosave = 1
nmap <F10> :RustRun<CR>

" rls
if executable('rls')
    au User lsp_setup call lsp#register_server({
        \ 'name': 'rls',
        \ 'cmd': {server_info->['rustup', 'run', 'stable', 'rls']},
        \ 'workspace_config': {'rust': {'clippy_preference': 'on'}},
        \ 'whitelist': ['rust'],
        \ })
endif

" asyncomplete
imap <c-space> <Plug>(asyncomplete_force_refresh)
inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <expr> <cr>    pumvisible() ? "\<C-y>" : "\<cr>"

" escape
inoremap jj <Esc>

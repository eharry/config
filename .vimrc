set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

" let Vundle manage Vundle, required
    Plugin 'VundleVim/Vundle.vim'

" All of your Plugins must be added before the following line
    Plugin 'tomasr/molokai'
    Plugin 'altercation/vim-colors-solarized'
    Plugin 'asins/vimcdoc'
    Plugin 'Mizuchi/STL-Syntax'
    Plugin 'vim-scripts/a.vim'
    Plugin 'mileszs/ack.vim'
    Plugin 'vim-scripts/winmanager'
    Plugin 'taglist.vim'
    Plugin 'godlygeek/tabular'
    Plugin 'portante/cscope'
    Plugin 'yegappan/mru'
    Plugin 'rking/ag.vim'
    Plugin 'aceofall/gtags.vim'
    Plugin 'MattesGroeger/vim-bookmarks'
    Plugin 'genutils'
    Plugin 'lookupfile'
    Plugin 'vim-scripts/c.vim'

    "-------------------=== Code/Project navigation ===-------------
    Plugin 'scrooloose/nerdtree'                " Project and file navigation
    Plugin 'majutsushi/tagbar'                  " Class/module browser
"    Plugin 'kien/ctrlp.vim'                     " Fast transitions on project files

    "-------------------=== Other ===-------------------------------
    Plugin 'bling/vim-airline'                  " Lean & mean status/tabline for vim
    Plugin 'vim-airline/vim-airline-themes'     " Themes for airline
    Plugin 'Lokaltog/powerline'                 " Powerline fonts plugin
    Plugin 'fisadev/FixedTaskList.vim'          " Pending tasks list
    Plugin 'rosenfeld/conque-term'              " Consoles as buffers
    Plugin 'tpope/vim-surround'                 " Parentheses, brackets, quotes, XML tags, and more
    Plugin 'flazz/vim-colorschemes'             " Colorschemes

    "-------------------=== Snippets support ===--------------------
    Plugin 'garbas/vim-snipmate'                " Snippets manager
    Plugin 'MarcWeber/vim-addon-mw-utils'       " dependencies #1
    Plugin 'tomtom/tlib_vim'                    " dependencies #2
    Plugin 'honza/vim-snippets'                 " snippets repo

    "-------------------=== Languages support ===-------------------
    Plugin 'tpope/vim-commentary'               " Comment stuff out
    Plugin 'mitsuhiko/vim-sparkup'              " Sparkup(XML/jinja/htlm-django/etc.) support
    Plugin 'Rykka/riv.vim'                      " ReStructuredText plugin
"    Plugin 'Valloric/YouCompleteMe'             " Autocomplete plugin

    "-------------------=== Python  ===-----------------------------
    Plugin 'klen/python-mode'                   " Python mode (docs, refactor, lints...)
"    Plugin 'scrooloose/syntastic'               " Syntax checking plugin for Vim

    " Colors
    Plugin 'colepeters/spacemacs-theme.vim'
    Plugin 'sheerun/vim-polyglot'
    
    " Edit
    Plugin 'SirVer/ultisnips'
    Plugin 'matze/vim-move'
    Plugin 'jiangmiao/auto-pairs'
    Plugin 'kana/vim-operator-user'
    Plugin 'gcmt/wildfire.vim'
    Plugin 'lilydjwg/fcitx.vim'
    
    " Browsing
    Plugin 'Yggdroot/indentLine'
"    Plugin 'majutsushi/tagbar', { 'on': 'TagbarToggle'      }
    Plugin 'derekwyatt/vim-fswitch', { 'for': ['c', 'cpp', 'objc'] }
    Plugin 'derekwyatt/vim-protodef', { 'for': ['c', 'cpp', 'objc'] }
    Plugin 'scrooloose/nerdcommenter'
    Plugin 'suan/vim-instant-markdown', { 'for': 'markdown' }
    Plugin 'tpope/vim-fugitive'
    
    
"    Plugin 'fholgado/minibufexpl.vim'
"    Plugin 'bling/vim-bufferline'
    Plugin 'sjl/gundo.vim'
    Plugin 'dyng/ctrlsf.vim'

call vundle#end()            " required

filetype on
filetype plugin on
filetype plugin indent on

"=====================================================
"" General settings
"=====================================================
syntax enable                               " syntax highlight

let mapleader = ' '

set t_Co=256                                " set 256 colors

set number                                  " show line numbers
set ttyfast                                 " terminal acceleration

set smarttab                                " set tabs for a shifttabs logic
set expandtab                               " expand tabs into spaces
set autoindent                              " indent when moving to the next line while writing code

"set cursorline                              " shows line under the cursor's line
set showmatch                               " shows matching part of bracket pairs (), [], {}

set enc=utf-8	                            " utf-8 by default

set nobackup 	                            " no backup files
set nowritebackup                           " only in case you don't want a backup file while editing
set noswapfile 	                            " no swap files

set backspace=indent,eol,start              " backspace removes all (indents, EOLs, start) What is start?

set scrolloff=10                            " let 10 lines before/after cursor during scroll

set clipboard=unnamed                       " use system clipboard

set exrc                                    " enable usage of additional .vimrc files from working directory
set secure                                  " prohibit .vimrc files to execute shell, create files, etc...


"=====================================================
"" Tabs / Buffers settings
"=====================================================
tab sball
set switchbuf=useopen

"" Search settings
"=====================================================
set incsearch	                            " incremental search
set hlsearch	                            " highlight search results

"=====================================================
"" AirLine settings
"=====================================================
let g:airline_theme='badwolf'
let g:airline#extensions#tabline#enabled=1
let g:airline#extensions#tabline#formatter='unique_tail'
let g:airline_powerline_fonts=1

"=====================================================
"" TagBar settings
"=====================================================
let g:tagbar_autofocus=0
let g:tagbar_width=42
autocmd BufEnter *.py :call tagbar#autoopen(0)
autocmd BufWinLeave *.py :TagbarClose

"=====================================================
"" NERDTree settings
"=====================================================
let NERDTreeIgnore=['\.pyc$', '\.pyo$', '__pycache__$']     " Ignore files in NERDTree

"=====================================================
"" SnipMate settings
"=====================================================
let g:snippets_dir='~/.vim/vim-snippets/snippets'

"=====================================================
"" Riv.vim settings
"=====================================================
let g:riv_disable_folding=1

"=====================================================
"" Python settings
"=====================================================

" python executables for different plugins
let g:pymode_python='python'
let g:syntastic_python_python_exec='python'

" rope
let g:pymode_rope=0
let g:pymode_rope_completion=0
let g:pymode_rope_complete_on_dot=0
let g:pymode_rope_auto_project=0
let g:pymode_rope_enable_autoimport=0
let g:pymode_rope_autoimport_generate=0
let g:pymode_rope_guess_project=0

" documentation
let g:pymode_doc=0
let g:pymode_doc_key='K'

" lints
let g:pymode_lint=0

" virtualenv
let g:pymode_virtualenv=1

" breakpoints
let g:pymode_breakpoint=1
let g:pymode_breakpoint_key='<leader>b'

" syntax highlight
" let g:pymode_syntax=1
" let g:pymode_syntax_slow_sync=1
" let g:pymode_syntax_all=1
" let g:pymode_syntax_print_as_function=g:pymode_syntax_all
" let g:pymode_syntax_highlight_async_await=g:pymode_syntax_all
" let g:pymode_syntax_highlight_equal_operator=g:pymode_syntax_all
" let g:pymode_syntax_highlight_stars_operator=g:pymode_syntax_all
" let g:pymode_syntax_highlight_self=g:pymode_syntax_all
" let g:pymode_syntax_indent_errors=g:pymode_syntax_all
" let g:pymode_syntax_string_formatting=g:pymode_syntax_all
" let g:pymode_syntax_space_errors=g:pymode_syntax_all
" let g:pymode_syntax_string_format=g:pymode_syntax_all
" let g:pymode_syntax_string_templates=g:pymode_syntax_all
" let g:pymode_syntax_doctests=g:pymode_syntax_all
" let g:pymode_syntax_builtin_objs=g:pymode_syntax_all
" let g:pymode_syntax_builtin_types=g:pymode_syntax_all
" let g:pymode_syntax_highlight_exceptions=g:pymode_syntax_all
" let g:pymode_syntax_docstrings=g:pymode_syntax_all

" highlight 'long' lines (>= 80 symbols) in python files
" augroup vimrc_autocmds
"     autocmd!
"     autocmd FileType python,rst,c,cpp highlight Excess ctermbg=DarkGrey guibg=Black
"     autocmd FileType python,rst,c,cpp match Excess /\%81v.*/
"     autocmd FileType python,rst,c,cpp set nowrap
"     autocmd FileType python,rst,c,cpp set colorcolumn=80
" augroup END

" code folding
let g:pymode_folding=0

" pep8 indents
let g:pymode_indent=1

" code running
let g:pymode_run=1
let g:pymode_run_bind='<F5>'

" syntastic
let g:syntastic_always_populate_loc_list=1
let g:syntastic_auto_loc_list=1
let g:syntastic_enable_signs=1
let g:syntastic_check_on_wq=0
let g:syntastic_aggregate_errors=1
let g:syntastic_loc_list_height=5
let g:syntastic_error_symbol='X'
let g:syntastic_style_error_symbol='X'
let g:syntastic_warning_symbol='x'
let g:syntastic_style_warning_symbol='x'
let g:syntastic_python_checkers=['flake8', 'pydocstyle', 'python']


set encoding=utf-8

" Allow backspacing over everything in insert mode
set backspace=indent,eol,start

" Store lots of :cmdline history
set history=500

" Show line numbers
set nu

"set nowrap

" Autoindent when starting new line
set autoindent
set smartindent
set lazyredraw

" Ignore case when searching
set ignorecase 

" Don't ignore case when search has capital letter
set smartcase

" Enable highlighted case-insensitive incremential search
set incsearch

" Enble search highlighting
set hlsearch

" Always show window statuses
set laststatus=2

" Statusline style
set statusline=
set statusline+=%7*\[%n]                                  "buffernr
set statusline+=%1*\ %<%F\                                "File+path
set statusline+=%2*\ %y\                                  "FileType
set statusline+=%3*\ %{''.(&fenc!=''?&fenc:&enc).''}      "Encoding
set statusline+=%3*\ %{(&bomb?\",BOM\":\"\")}\            "Encoding2
set statusline+=%4*\ %{&ff}\                              "FileFormat (dos/unix..) 
set statusline+=%8*\ %=\ row:%l/%L\ (%p%%)\             "Rownumber/total (%)
set statusline+=%9*\ col:%c\                            "Colnr
set statusline+=%0*\ \ %m%r%w\ %P\ \                      "Modified? Readonly? Top/bot.

" Show the size of block one selected in visual mode
set showcmd

" Hide buffers
set hidden
set visualbell

" Indent using four spaces
set expandtab smarttab
set tabstop=2
set shiftwidth=2
set softtabstop=2

set gcr=a:block-blinkon0

" Show the line and column number of the cursor position
set ruler



" <<<<
" >>>>
" MAPPINGS

" ----------------------------------------------------------------------------
" Basic mappings
" ----------------------------------------------------------------------------

" Edit myvimrc
nnoremap <leader>ev :vsplit <cr>
nnoremap <leader>sv :split <cr>
nnoremap <leader>ss :source $MYVIMRC<cr>

" Edit
nnoremap <leader>r" viw<esc>a"<esc>hbi"<esc>lel

" Save
nnoremap <leader>w :w<cr>


" Copy
vnoremap <Leader>y "+y
nmap <Leader>p "+p

" Quit
nnoremap <Leader>q :q<cr>
nnoremap <Leader>Q :qa!<cr>

" Movement in insert mode
inoremap <C-h> <C-o>h
inoremap <C-j> <C-o>j
inoremap <C-k> <C-o>k
inoremap <C-l> <C-o>a
inoremap <C-^> <C-o><C-^>

" ----------------------------------------------------------------------------
" Quickfix
" ----------------------------------------------------------------------------

nnoremap ]q :cnext<cr>zz
nnoremap [q :cprev<cr>zz

" ----------------------------------------------------------------------------
" <tab> / <s-tab> | Circular windows navigation
" ----------------------------------------------------------------------------

nnoremap <tab>   <c-w>w
nnoremap <S-tab> <c-w>W
nnoremap <Leader>hw <C-W>h
nnoremap <Leader>jw <C-W>j
nnoremap <Leader>kw <C-W>k
nnoremap <Leader>lw <C-W>l

" ----------------------------------------------------------------------------
" :CopyRTF
" ----------------------------------------------------------------------------

function! s:colors(...)
return filter(map(filter(split(globpath(&rtp, 'colors/*.vim'), "\n"),
    \                  'v:val !~ "^/usr/"'),
    \           'fnamemodify(v:val, ":t:r")'),
    \       '!a:0 || stridx(v:val, a:1) >= 0')
endfunction

set background=dark
colorschem solarized

nmap <silent> <Leader>jj <C-f>
nmap <silent> <Leader>kk <C-b>

" <<<<
" >>>>
" PLUGINS

" ----------------------------------------------------------------------------
" ultisnips
" ----------------------------------------------------------------------------

let g:UltiSnipsSnippetDirectories=["mysnippets"]
let g:UltiSnipsExpandTrigger="<leader><tab>"
let g:UltiSnipsJumpForwardTrigger="<leader><tab>"
let g:UltiSnipsJumpBackwardTrigger="<leader><s-tab>"

" ----------------------------------------------------------------------------
" vim-multiple-cursors
" ----------------------------------------------------------------------------

let g:multi_cursor_next_key='<S-n>'
let g:multi_cursor_skip_key='<S-k>'

" ----------------------------------------------------------------------------
" vim-move
" ----------------------------------------------------------------------------

let g:move_key_modifier = 'C'

" ----------------------------------------------------------------------------
" auto-pairs
" ----------------------------------------------------------------------------

" ----------------------------------------------------------------------------
" vim-operator-user
" ----------------------------------------------------------------------------

" ----------------------------------------------------------------------------
" wildfire.vim
" ----------------------------------------------------------------------------

map <SPACE> <Plug>(wildfire-fuel)
vmap <C-SPACE> <Plug>(wildfire-water)

" ----------------------------------------------------------------------------
" indentLine
" ----------------------------------------------------------------------------
  
let g:indentLine_char = '│'

" ----------------------------------------------------------------------------
" tarbar
" ----------------------------------------------------------------------------

inoremap <F2> <esc>:TagbarToggle<cr>
nnoremap <F2> :TagbarToggle<cr>

let tagbar_left=1
let tagbar_width=32
let g:tagbar_sort = 0
let g:tagbar_compact=1
let g:tagbar_type_cpp = {
 \ 'ctagstype' : 'c++',
 \ 'kinds'     : [
     \ 'c:classes:0:1',
     \ 'd:macros:0:1',
     \ 'e:enumerators:0:0', 
     \ 'f:functions:0:1',
     \ 'g:enumeration:0:1',
     \ 'l:local:0:1',
     \ 'm:members:0:1',
     \ 'n:namespaces:0:1',
     \ 'p:functions_prototypes:0:1',
     \ 's:structs:0:1',
     \ 't:typedefs:0:1',
     \ 'u:unions:0:1',
     \ 'v:global:0:1',
     \ 'x:external:0:1'
 \ ],
 \ 'sro'        : '::',
 \ 'kind2scope' : {
     \ 'g' : 'enum',
     \ 'n' : 'namespace',
     \ 'c' : 'class',
     \ 's' : 'struct',
     \ 'u' : 'union'
 \ },
 \ 'scope2kind' : {
     \ 'enum'      : 'g',
     \ 'namespace' : 'n',
     \ 'class'     : 'c',
     \ 'struct'    : 's',
     \ 'union'     : 'u'
 \ }
\ }

" ----------------------------------------------------------------------------
" vim-fswitch
" ----------------------------------------------------------------------------

nmap <silent> <Leader>fs :FSHere<cr>

" ----------------------------------------------------------------------------
" vim-protodef
" ----------------------------------------------------------------------------

let g:protodefprotogetter='~/.vim/plugged/vim-protodef/pullproto.pl'
let g:disable_protodef_sorting=1

" ----------------------------------------------------------------------------
" nerdcommenter
" ----------------------------------------------------------------------------

" ----------------------------------------------------------------------------
" nerdtree
" ----------------------------------------------------------------------------

nnoremap :tree <esc>:NERDTreeToggle<CR>

let NERDTreeWinSize=22
let NERDTreeWinPos="right"
let NERDTreeShowHidden=0
let NERDTreeMinimalUI=1
let NERDTreeAutoDeleteBuffer=1

" ----------------------------------------------------------------------------
" vim-instant-markdown
" ----------------------------------------------------------------------------

autocmd BufNewFile,BufReadPost *.md set filetype=markdown

let g:instant_markdown_slow = 1
let g:instant_markdown_autostart = 0

nnoremap <Leader>md :InstantMarkdownPreview<CR>


" ----------------------------------------------------------------------------
" vim-fugitive
" ----------------------------------------------------------------------------


  
set updatetime=250

let g:gitgutter_sign_column_always = 1

" ----------------------------------------------------------------------------
" minibufexpl
" ----------------------------------------------------------------------------

nnoremap <Leader>mb :MBEToggle<cr>

nnoremap ]b :bnext<cr>
nnoremap [b :bprev<cr>

" ----------------------------------------------------------------------------
" gundo.vim
" ----------------------------------------------------------------------------

nnoremap <Leader>ud :GundoToggle<CR>

set sessionoptions="blank,globals,localoptions,tabpages,sesdir,folds,help,options,resize,winpos,winsize"

if !strlen(finddir('~/.vim/undofiles'))
echo "undofiles[~/.vim/undofiles] not found. Now it's being created. Press ENTER or type command to continue."
!mkdir -p ~/.vim/undofiles
endif

set undodir=~/.vim/undofiles
set undofile
"set colorcolumn=+1 

" ----------------------------------------------------------------------------
" ctrlsf.vim
" ----------------------------------------------------------------------------

"nnoremap <c-f> :CtrlSF<CR>

" ----------------------------------------------------------------------------
" ctrlp.vim
" ----------------------------------------------------------------------------

" Disable output, vcs, archive, rails, temp and backup files
" set wildignore+=*.o,*.out,*.obj,.git,*.pyc,*.class
" set wildignore+=*.zip,*.tar.gz,*.tar.bz2,*.rar,*.tar.xz
" set wildignore+=*.swp,*~,._*
" set wildignore+=*/tmp/*,*.so,*.swp,*.zip     " MacOSX/Linux
" 
" let g:ctrlp_map = '<s-p>'
" let g:ctrlp_cmd = 'CtrlP'
" let g:ctrlp_custom_ignore = '\v[\/]\.(git|hg|svn)$'
" let g:ctrlp_custom_ignore = {
"   \ 'dir':  '\v[\/]\.(git|hg|svn|vendor/bundle/*\|vendor/cache/*\|public\|spec)$',
"   \ 'file': '\v\.(exe|so|dll|swp|log|jpg|png|json)$',
"   \ }


"  gtags
nnoremap <leader>qf :copen<cr>
nmap <C-@>r :Gtags -r <C-R>=expand("<cword>")<CR><CR>
nmap <C-@>s :Gtags -s <C-R>=expand("<cword>")<CR><CR>
nmap <C-@>g :Gtags -g <C-R>=expand("<cword>")<CR><CR>

"""""""""""""""""""""""""""""" 
" lookupfile setting
"""""""""""""""""""""""""""""" 
let g:LookupFile_MinPatLength = 2               "最少输入2个字符才开始查找
let g:LookupFile_PreserveLastPattern = 0        "不保存上次查找的字符串
let g:LookupFile_PreservePatternHistory = 1     "保存查找历史
let g:LookupFile_AlwaysAcceptFirst = 1          "回车打开第一个匹配项目
let g:LookupFile_AllowNewFiles = 0              "不允许创建不存在的文件
if filereadable("./filenametags")                "设置tag文件的名字
let g:LookupFile_TagExpr = '"./filenametags"'
endif
"映射LookupFile为,lk
nmap <silent> <leader>lk :LUTags<cr>
"映射LUBufs为,ll
nmap <silent> <leader>ll :LUBufs<cr>
"映射LUWalk为,lw
nmap <silent> <leader>lw :LUWalk<cr>

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" cscope setting
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if has("cscope")
  set csprg=/usr/local/bin/cscope
  set csto=1
  set cst
  set nocsverb
  " add any database in current directory
  if filereadable("cscope.out")
      cs add cscope.out
  endif
  set csverb
endif

nmap <C-@>s :cs find s <C-R>=expand("<cword>")<CR><CR>
nmap <C-@>g :cs find g <C-R>=expand("<cword>")<CR><CR>
nmap <C-@>c :cs find c <C-R>=expand("<cword>")<CR><CR>
nmap <C-@>t :cs find t <C-R>=expand("<cword>")<CR><CR>
nmap <C-@>e :cs find e <C-R>=expand("<cword>")<CR><CR>
nmap <C-@>f :cs find f <C-R>=expand("<cfile>")<CR><CR>
nmap <C-@>i :cs find i ^<C-R>=expand("<cfile>")<CR>$<CR>
nmap <C-@>d :cs find d <C-R>=expand("<cword>")<CR><CR>

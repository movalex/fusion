let SessionLoad = 1
if &cp | set nocp | endif
let s:cpo_save=&cpo
set cpo&vim
imap <Nul> <C-Space>
inoremap <expr> <Up> pumvisible() ? "\" : "\<Up>"
inoremap <expr> <S-Tab> pumvisible() ? "\" : "\<S-Tab>"
inoremap <expr> <Down> pumvisible() ? "\" : "\<Down>"
inoremap <silent> <Plug>NERDCommenterInsert  <BS>:call NERDComment('i', "insert")
inoremap <silent> <SNR>21_AutoPairsReturn =AutoPairsReturn()
imap <C-Down> j
imap <C-Up> k
imap <C-Left> h
imap <C-Right> l
nmap  :w:!python % 
nnoremap <silent>  :call g:ToggleNuMode()
noremap  :noh
nnoremap <silent>  :CtrlPMRU
nmap  <Plug>(RepeatRedo)
nnoremap ,d :YcmShowDetailedDiagnostic
nmap ,ca <Plug>NERDCommenterAltDelims
xmap ,cu <Plug>NERDCommenterUncomment
nmap ,cu <Plug>NERDCommenterUncomment
xmap ,cb <Plug>NERDCommenterAlignBoth
nmap ,cb <Plug>NERDCommenterAlignBoth
xmap ,cl <Plug>NERDCommenterAlignLeft
nmap ,cl <Plug>NERDCommenterAlignLeft
nmap ,cA <Plug>NERDCommenterAppend
xmap ,cy <Plug>NERDCommenterYank
nmap ,cy <Plug>NERDCommenterYank
xmap ,cs <Plug>NERDCommenterSexy
nmap ,cs <Plug>NERDCommenterSexy
xmap ,ci <Plug>NERDCommenterInvert
nmap ,ci <Plug>NERDCommenterInvert
nmap ,c$ <Plug>NERDCommenterToEOL
xmap ,cn <Plug>NERDCommenterNested
nmap ,cn <Plug>NERDCommenterNested
xmap ,cm <Plug>NERDCommenterMinimal
nmap ,cm <Plug>NERDCommenterMinimal
xmap ,c  <Plug>NERDCommenterToggle
nmap ,c  <Plug>NERDCommenterToggle
xmap ,cc <Plug>NERDCommenterComment
nmap ,cc <Plug>NERDCommenterComment
nmap . <Plug>(RepeatDot)
inoremap ë :m .-2==gi
inoremap ê :m .+1==gi
xmap S <Plug>VSurround
nmap U <Plug>(RepeatUndoLine)
nnoremap \s :%s/\<\>/
map ^[OD <Left>
map ^[OC <Right>
map ^[OB <Down>
map ^[OA <Up>
nmap cS <Plug>CSurround
nmap cs <Plug>Csurround
nmap ds <Plug>Dsurround
vmap gx <Plug>NetrwBrowseXVis
nmap gx <Plug>NetrwBrowseX
xmap gS <Plug>VgSurround
nmap u <Plug>(RepeatUndo)
nmap ySS <Plug>YSsurround
nmap ySs <Plug>YSsurround
nmap yss <Plug>Yssurround
nmap yS <Plug>YSurround
nmap ys <Plug>Ysurround
nnoremap <silent> <Plug>(RepeatRedo) :call repeat#wrap("\<C-R>",v:count)
nnoremap <silent> <Plug>(RepeatUndoLine) :call repeat#wrap('U',v:count)
nnoremap <silent> <Plug>(RepeatUndo) :call repeat#wrap('u',v:count)
nnoremap <silent> <Plug>(RepeatDot) :exe repeat#run(v:count)
vnoremap <silent> <Plug>NetrwBrowseXVis :call netrw#BrowseXVis()
nnoremap <silent> <Plug>NetrwBrowseX :call netrw#BrowseX(expand((exists("g:netrw_gx")? g:netrw_gx : '<cfile>')),netrw#CheckIfRemote())
xnoremap <silent> <Plug>NERDCommenterUncomment :call NERDComment("x", "Uncomment")
nnoremap <silent> <Plug>NERDCommenterUncomment :call NERDComment("n", "Uncomment")
xnoremap <silent> <Plug>NERDCommenterAlignBoth :call NERDComment("x", "AlignBoth")
nnoremap <silent> <Plug>NERDCommenterAlignBoth :call NERDComment("n", "AlignBoth")
xnoremap <silent> <Plug>NERDCommenterAlignLeft :call NERDComment("x", "AlignLeft")
nnoremap <silent> <Plug>NERDCommenterAlignLeft :call NERDComment("n", "AlignLeft")
nnoremap <silent> <Plug>NERDCommenterAppend :call NERDComment("n", "Append")
xnoremap <silent> <Plug>NERDCommenterYank :call NERDComment("x", "Yank")
nnoremap <silent> <Plug>NERDCommenterYank :call NERDComment("n", "Yank")
xnoremap <silent> <Plug>NERDCommenterSexy :call NERDComment("x", "Sexy")
nnoremap <silent> <Plug>NERDCommenterSexy :call NERDComment("n", "Sexy")
xnoremap <silent> <Plug>NERDCommenterInvert :call NERDComment("x", "Invert")
nnoremap <silent> <Plug>NERDCommenterInvert :call NERDComment("n", "Invert")
nnoremap <silent> <Plug>NERDCommenterToEOL :call NERDComment("n", "ToEOL")
xnoremap <silent> <Plug>NERDCommenterNested :call NERDComment("x", "Nested")
nnoremap <silent> <Plug>NERDCommenterNested :call NERDComment("n", "Nested")
xnoremap <silent> <Plug>NERDCommenterMinimal :call NERDComment("x", "Minimal")
nnoremap <silent> <Plug>NERDCommenterMinimal :call NERDComment("n", "Minimal")
xnoremap <silent> <Plug>NERDCommenterToggle :call NERDComment("x", "Toggle")
nnoremap <silent> <Plug>NERDCommenterToggle :call NERDComment("n", "Toggle")
xnoremap <silent> <Plug>NERDCommenterComment :call NERDComment("x", "Comment")
nnoremap <silent> <Plug>NERDCommenterComment :call NERDComment("n", "Comment")
nnoremap <silent> <Plug>SurroundRepeat .
xnoremap <Plug>ColorFgBg :ColorSwapFgBg
nnoremap <Plug>ColorFgBg :ColorSwapFgBg
xnoremap <Plug>ColorContrast :ColorContrast
nnoremap <Plug>ColorContrast :ColorContrast
xnoremap <Plug>Colorizer :ColorHighlight
nnoremap <Plug>Colorizer :ColorToggle
nmap <F7> :terminaljR14+
nmap <F6> :NERDTreeToggle
nmap <F5> :w:!python % 
nnoremap <C-Down> j
nnoremap <C-Up> k
nnoremap <C-Left> h
nnoremap <C-Right> l
noremap <D-0> :tablast
noremap <D-9> :tabn 9
noremap <D-8> :tabn 8
noremap <D-7> :tabn 7
noremap <D-6> :tabn 6
noremap <D-5> :tabn 5
noremap <D-4> :tabn 4
noremap <D-3> :tabn 3
noremap <D-2> :tabn 2
noremap <D-1> :tabn 1
noremap <C-S-Tab> :tabprev
noremap <C-Tab> :tabnext
vmap <S-Up> k
vmap <S-Down> j
nmap <S-Up> V
nmap <S-Down> V 
vmap <BS> "-d
imap S <Plug>ISurround
imap s <Plug>Isurround
inoremap <expr> 	 pumvisible() ? "\" : "\	"
imap  <Plug>Isurround
nnoremap  :call ChooseTerm("term-pane", 0)
nnoremap Ô :call ChooseTerm("term-slider", 1)
vnoremap ë :m '<-2gv=gv
vnoremap ê :m '>+1gv=gv
nnoremap ë :m .-2==
nnoremap ê :m .+1==
cmap w!! w !sudo tee % > /dev/null %
let &cpo=s:cpo_save
unlet s:cpo_save
set autochdir
set backspace=indent,eol,start
set completefunc=youcompleteme#CompleteFunc
set completeopt=preview,menuone
set cpoptions=aAceFsB
set expandtab
set fileencodings=ucs-bom,utf-8,default,latin1
set guifont=Fira\ Code:h15
set guioptions=egm
set hlsearch
set ignorecase
set langmenu=none
set laststatus=2
set linespace=7
set macligatures
set macmeta
set pythonthreedll=~/.pyenv/versions/3.6.8/lib/libpython3.6m.dylib
set pythonthreehome=~/.pyenv/versions/3.6.8
set pyxversion=3
set runtimepath=
set runtimepath+=~/.vim
set runtimepath+=~/.vim/bundle/Vundle.vim
set runtimepath+=~/.vim/bundle/Colorizer
set runtimepath+=~/.vim/bundle/scss-syntax.vim
set runtimepath+=~/.vim/bundle/vim-wakatime
set runtimepath+=~/.vim/bundle/YouCompleteMe
set runtimepath+=~/.vim/bundle/vim-airline-themes
set runtimepath+=~/.vim/bundle/onehalf/vim/
set runtimepath+=~/.vim/bundle/python-mode
set runtimepath+=~/.vim/bundle/auto-pairs
set runtimepath+=~/.vim/bundle/vim-surround
set runtimepath+=~/.vim/bundle/vim-repeat
set runtimepath+=~/.vim/bundle/nerdtree
set runtimepath+=~/.vim/bundle/nerdcommenter
set runtimepath+=~/.vim/bundle/vim-nerdtree-sync
set runtimepath+=~/.vim/bundle/vim-reveal-in-finder
set runtimepath+=~/.vim/bundle/ctrlp.vim
set runtimepath+=/usr/local/Cellar/macvim/HEAD-75ee1a5/MacVim.app/Contents/Resources/vim/vimfiles
set runtimepath+=/usr/local/Cellar/macvim/HEAD-75ee1a5/MacVim.app/Contents/Resources/vim/runtime
set runtimepath+=/usr/local/Cellar/macvim/HEAD-75ee1a5/MacVim.app/Contents/Resources/vim/vimfiles/after
set runtimepath+=~/.vim/after
set runtimepath+=~/.vim/bundle/Vundle.vim
set runtimepath+=~/.vim/bundle/Vundle.vim/after
set runtimepath+=~/.vim/bundle/Colorizer/after
set runtimepath+=~/.vim/bundle/scss-syntax.vim/after
set runtimepath+=~/.vim/bundle/vim-wakatime/after
set runtimepath+=~/.vim/bundle/YouCompleteMe/after
set runtimepath+=~/.vim/bundle/vim-airline-themes/after
set runtimepath+=~/.vim/bundle/onehalf/vim//after
set runtimepath+=~/.vim/bundle/python-mode/after
set runtimepath+=~/.vim/bundle/auto-pairs/after
set runtimepath+=~/.vim/bundle/vim-surround/after
set runtimepath+=~/.vim/bundle/vim-repeat/after
set runtimepath+=~/.vim/bundle/nerdtree/after
set runtimepath+=~/.vim/bundle/nerdcommenter/after
set runtimepath+=~/.vim/bundle/vim-nerdtree-sync/after
set runtimepath+=~/.vim/bundle/vim-reveal-in-finder/after
set shiftround
set shiftwidth=4
set shortmess=filnxtToOc
set softtabstop=4
set statusline=%#PmenuSel#%#LineNr#\ %f%m\\%=%#CursorColumn#\ %y\ %{&fileencoding?&fileencoding:&encoding}[%{&fileformat}]\ %p%%\ %l:%c\ 
set noswapfile
set wildignore=*.pyc
let s:so_save = &so | let s:siso_save = &siso | set so=0 siso=0
let v:this_session=expand("<sfile>:p")
silent only
silent tabonly
cd ~/Documents/git/MyScripts/fusion_scripts/Scripts/Comp
if expand('%') == '' && !&modified && line('$') <= 1 && getline(1) == ''
  let s:wipebuf = bufnr('%')
endif
set shortmess=aoO
argglobal
%argdel
edit ~/Documents/git/MyScripts/fusion_scripts/Scripts/Comp/bookmark_jump.py
set splitbelow splitright
wincmd _ | wincmd |
vsplit
1wincmd h
wincmd w
set nosplitbelow
set nosplitright
wincmd t
set winminheight=0
set winheight=1
set winminwidth=0
set winwidth=1
exe 'vert 1resize ' . ((&columns * 118 + 118) / 237)
exe 'vert 2resize ' . ((&columns * 118 + 118) / 237)
argglobal
let s:cpo_save=&cpo
set cpo&vim
inoremap <buffer> <silent> <BS> =AutoPairsDelete()
nnoremap <buffer> <silent> ,b :call pymode#breakpoint#operate(line('.'))
vnoremap <buffer> <silent> ,r :PymodeRun
nnoremap <buffer> <silent> ,r :PymodeRun
inoremap <buffer> <silent> § =AutoPairsMoveCharacter('''')
inoremap <buffer> <silent> ¢ =AutoPairsMoveCharacter('"')
inoremap <buffer> <silent> © =AutoPairsMoveCharacter(')')
inoremap <buffer> <silent> ¨ =AutoPairsMoveCharacter('(')
inoremap <buffer> <silent> î :call AutoPairsJump()a
inoremap <buffer> <silent> <expr> ð AutoPairsToggle()
inoremap <buffer> <silent> â =AutoPairsBackInsert()
inoremap <buffer> <silent> å =AutoPairsFastWrap()
inoremap <buffer> <silent> ý =AutoPairsMoveCharacter('}')
inoremap <buffer> <silent> û =AutoPairsMoveCharacter('{')
inoremap <buffer> <silent> Ý =AutoPairsMoveCharacter(']')
inoremap <buffer> <silent> Û =AutoPairsMoveCharacter('[')
onoremap <buffer> C :call pymode#motion#select('^\s*class\s', 0)
vnoremap <buffer> <silent> K :call pymode#doc#show(@*)
nnoremap <buffer> <silent> K :call pymode#doc#find()
onoremap <buffer> M :call pymode#motion#select('^\s*\(async\s\+\)\=def\s', 0)
onoremap <buffer> [C :call pymode#motion#move('^\(class\|\%(async\s\+\)\=def\)\s', 'b')
nnoremap <buffer> [C :call pymode#motion#move('^\(class\|\%(async\s\+\)\=def\)\s', 'b')
vnoremap <buffer> [M :call pymode#motion#vmove('^\s*\(async\s\+\)\=def\s', 'b')
vnoremap <buffer> [[ :call pymode#motion#vmove('^\(class\|\%(async\s\+\)\=def\)\s', 'b')
onoremap <buffer> [M :call pymode#motion#move('^\s*\(async\s\+\)\=def\s', 'b')
onoremap <buffer> [[ :call pymode#motion#move('^\(class\|\%(async\s\+\)\=def\)\s', 'b')
nnoremap <buffer> [M :call pymode#motion#move('^\s*\(async\s\+\)\=def\s', 'b')
nnoremap <buffer> [[ :call pymode#motion#move('^\(class\|\%(async\s\+\)\=def\)\s', 'b')
onoremap <buffer> ]C :call pymode#motion#move('^\(class\|\%(async\s\+\)\=def\)\s', '')
nnoremap <buffer> ]C :call pymode#motion#move('^\(class\|\%(async\s\+\)\=def\)\s', '')
vnoremap <buffer> ]M :call pymode#motion#vmove('^\s*\(async\s\+\)\=def\s', '')
vnoremap <buffer> ]] :call pymode#motion#vmove('^\(class\|\%(async\s\+\)\=def\)\s', '')
onoremap <buffer> ]M :call pymode#motion#move('^\s*\(async\s\+\)\=def\s', '')
onoremap <buffer> ]] :call pymode#motion#move('^\(class\|\%(async\s\+\)\=def\)\s', '')
nnoremap <buffer> ]M :call pymode#motion#move('^\s*\(async\s\+\)\=def\s', '')
nnoremap <buffer> ]] :call pymode#motion#move('^\(class\|\%(async\s\+\)\=def\)\s', '')
vnoremap <buffer> aM :call pymode#motion#select('^\s*\(async\s\+\)\=def\s', 0)
onoremap <buffer> aM :call pymode#motion#select('^\s*\(async\s\+\)\=def\s', 0)
vnoremap <buffer> aC :call pymode#motion#select('^\s*class\s', 0)
onoremap <buffer> aC :call pymode#motion#select('^\s*class\s', 0)
vnoremap <buffer> iM :call pymode#motion#select('^\s*\(async\s\+\)\=def\s', 1)
onoremap <buffer> iM :call pymode#motion#select('^\s*\(async\s\+\)\=def\s', 1)
vnoremap <buffer> iC :call pymode#motion#select('^\s*class\s', 1)
onoremap <buffer> iC :call pymode#motion#select('^\s*class\s', 1)
inoremap <buffer> <silent>  =AutoPairsDelete()
inoremap <buffer> <silent>   =AutoPairsSpace()
inoremap <buffer> <silent> " =AutoPairsInsert('"')
inoremap <buffer> <silent> ' =AutoPairsInsert('''')
inoremap <buffer> <silent> ( =AutoPairsInsert('(')
inoremap <buffer> <silent> ) =AutoPairsInsert(')')
noremap <buffer> <silent> î :call AutoPairsJump()
noremap <buffer> <silent> ð :call AutoPairsToggle()
inoremap <buffer> <silent> [ =AutoPairsInsert('[')
inoremap <buffer> <silent> ] =AutoPairsInsert(']')
inoremap <buffer> <silent> ` =AutoPairsInsert('`')
inoremap <buffer> <silent> { =AutoPairsInsert('{')
inoremap <buffer> <silent> } =AutoPairsInsert('}')
let &cpo=s:cpo_save
unlet s:cpo_save
setlocal keymap=
setlocal noarabic
setlocal autoindent
setlocal backupcopy=
setlocal balloonexpr=
setlocal nobinary
setlocal nobreakindent
setlocal breakindentopt=
setlocal bufhidden=
setlocal buflisted
setlocal buftype=
setlocal nocindent
setlocal cinkeys=0{,0},0),0],:,!^F,o,O,e
setlocal cinoptions=
setlocal cinwords=if,else,while,do,for,switch
setlocal colorcolumn=
setlocal comments=b:#,fb:-
setlocal commentstring=#\ %s
setlocal complete=.,w,b,u,t,i
setlocal concealcursor=
setlocal conceallevel=0
setlocal completefunc=youcompleteme#CompleteFunc
setlocal nocopyindent
setlocal cryptmethod=
setlocal nocursorbind
setlocal nocursorcolumn
set cursorline
setlocal cursorline
setlocal define=^s*\\(def\\|class\\)
setlocal dictionary=
setlocal nodiff
setlocal equalprg=
setlocal errorformat=
setlocal expandtab
if &filetype != 'python'
setlocal filetype=python
endif
setlocal fixendofline
setlocal foldcolumn=0
setlocal foldenable
setlocal foldexpr=0
setlocal foldignore=#
setlocal foldlevel=0
setlocal foldmarker={{{,}}}
setlocal foldmethod=manual
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldtext=foldtext()
setlocal formatexpr=
setlocal formatoptions=cq
setlocal formatlistpat=^\\s*\\d\\+[\\]:.)}\\t\ ]\\s*
setlocal formatprg=
setlocal grepprg=
setlocal iminsert=0
setlocal imsearch=-1
setlocal include=^\\s*\\(from\\|import\\)
setlocal includeexpr=substitute(substitute(substitute(v:fname,b:grandparent_match,b:grandparent_sub,''),b:parent_match,b:parent_sub,''),b:child_match,b:child_sub,'g')
setlocal indentexpr=pymode#indent#get_indent(v:lnum)
setlocal indentkeys=!^F,o,O,<:>,0),0],0},=elif,=except
setlocal noinfercase
setlocal iskeyword=@,48-57,_,192-255
setlocal keywordprg=pydoc
set linebreak
setlocal linebreak
setlocal nolisp
setlocal lispwords=
setlocal nolist
setlocal macmeta
setlocal makeencoding=
setlocal makeprg=
setlocal matchpairs=(:),{:},[:]
setlocal modeline
setlocal modifiable
setlocal nrformats=bin,octal,hex
set number
setlocal number
setlocal numberwidth=4
setlocal omnifunc=python3complete#Complete
setlocal path=
setlocal nopreserveindent
setlocal nopreviewwindow
setlocal quoteescape=\\
setlocal noreadonly
setlocal norelativenumber
setlocal norightleft
setlocal rightleftcmd=search
setlocal noscrollbind
setlocal scrolloff=-1
setlocal shiftwidth=4
setlocal noshortname
setlocal sidescrolloff=-1
setlocal signcolumn=auto
setlocal nosmartindent
setlocal softtabstop=4
setlocal nospell
setlocal spellcapcheck=[.?!]\\_[\\])'\"\	\ ]\\+
setlocal spellfile=
setlocal spelllang=en
setlocal statusline=
setlocal suffixesadd=.py
setlocal noswapfile
setlocal synmaxcol=3000
if &syntax != 'python'
setlocal syntax=python
endif
setlocal tabstop=4
setlocal tagcase=
setlocal tags=
setlocal termmode=
setlocal termwinkey=
setlocal termwinscroll=10000
setlocal termwinsize=
setlocal textwidth=79
setlocal thesaurus=
setlocal noundofile
setlocal undolevels=-123456
setlocal varsofttabstop=
setlocal vartabstop=
setlocal nowinfixheight
setlocal nowinfixwidth
setlocal nowrap
setlocal wrapmargin=0
silent! normal! zE
let s:l = 118 - ((51 * winheight(0) + 30) / 61)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
118
normal! 0
wincmd w
argglobal
if bufexists("~/Documents/git/MyScripts/fusion_scripts/Scripts/Comp/Rename_Plus.lua") | buffer ~/Documents/git/MyScripts/fusion_scripts/Scripts/Comp/Rename_Plus.lua | else | edit ~/Documents/git/MyScripts/fusion_scripts/Scripts/Comp/Rename_Plus.lua | endif
let s:cpo_save=&cpo
set cpo&vim
inoremap <buffer> <silent> <BS> =AutoPairsDelete()
inoremap <buffer> <silent> § =AutoPairsMoveCharacter('''')
inoremap <buffer> <silent> ¢ =AutoPairsMoveCharacter('"')
inoremap <buffer> <silent> © =AutoPairsMoveCharacter(')')
inoremap <buffer> <silent> ¨ =AutoPairsMoveCharacter('(')
inoremap <buffer> <silent> î :call AutoPairsJump()a
inoremap <buffer> <silent> <expr> ð AutoPairsToggle()
inoremap <buffer> <silent> â =AutoPairsBackInsert()
inoremap <buffer> <silent> å =AutoPairsFastWrap()
inoremap <buffer> <silent> ý =AutoPairsMoveCharacter('}')
inoremap <buffer> <silent> û =AutoPairsMoveCharacter('{')
inoremap <buffer> <silent> Ý =AutoPairsMoveCharacter(']')
inoremap <buffer> <silent> Û =AutoPairsMoveCharacter('[')
inoremap <buffer> <silent>  =AutoPairsDelete()
inoremap <buffer> <silent>   =AutoPairsSpace()
inoremap <buffer> <silent> " =AutoPairsInsert('"')
inoremap <buffer> <silent> ' =AutoPairsInsert('''')
inoremap <buffer> <silent> ( =AutoPairsInsert('(')
inoremap <buffer> <silent> ) =AutoPairsInsert(')')
noremap <buffer> <silent> î :call AutoPairsJump()
noremap <buffer> <silent> ð :call AutoPairsToggle()
inoremap <buffer> <silent> [ =AutoPairsInsert('[')
inoremap <buffer> <silent> ] =AutoPairsInsert(']')
inoremap <buffer> <silent> ` =AutoPairsInsert('`')
inoremap <buffer> <silent> { =AutoPairsInsert('{')
inoremap <buffer> <silent> } =AutoPairsInsert('}')
let &cpo=s:cpo_save
unlet s:cpo_save
setlocal keymap=
setlocal noarabic
setlocal autoindent
setlocal backupcopy=
setlocal balloonexpr=
setlocal nobinary
setlocal nobreakindent
setlocal breakindentopt=
setlocal bufhidden=
setlocal buflisted
setlocal buftype=
setlocal nocindent
setlocal cinkeys=0{,0},0),0],:,0#,!^F,o,O,e
setlocal cinoptions=
setlocal cinwords=if,else,while,do,for,switch
setlocal colorcolumn=
setlocal comments=:--
setlocal commentstring=--%s
setlocal complete=.,w,b,u,t,i
setlocal concealcursor=
setlocal conceallevel=0
setlocal completefunc=youcompleteme#CompleteFunc
setlocal nocopyindent
setlocal cryptmethod=
setlocal nocursorbind
setlocal nocursorcolumn
set cursorline
setlocal cursorline
setlocal define=
setlocal dictionary=
setlocal nodiff
setlocal equalprg=
setlocal errorformat=
setlocal expandtab
if &filetype != 'lua'
setlocal filetype=lua
endif
setlocal fixendofline
setlocal foldcolumn=0
setlocal foldenable
setlocal foldexpr=0
setlocal foldignore=#
setlocal foldlevel=0
setlocal foldmarker={{{,}}}
setlocal foldmethod=manual
setlocal foldminlines=1
setlocal foldnestmax=20
setlocal foldtext=foldtext()
setlocal formatexpr=
setlocal formatoptions=croql
setlocal formatlistpat=^\\s*\\d\\+[\\]:.)}\\t\ ]\\s*
setlocal formatprg=
setlocal grepprg=
setlocal iminsert=0
setlocal imsearch=-1
setlocal include=
setlocal includeexpr=
setlocal indentexpr=GetLuaIndent()
setlocal indentkeys=0{,0},0),0],:,0#,!^F,o,O,e,0=end,0=until
setlocal noinfercase
setlocal iskeyword=@,48-57,_,192-255
setlocal keywordprg=
set linebreak
setlocal linebreak
setlocal nolisp
setlocal lispwords=
setlocal nolist
setlocal macmeta
setlocal makeencoding=
setlocal makeprg=
setlocal matchpairs=(:),{:},[:]
setlocal modeline
setlocal modifiable
setlocal nrformats=bin,octal,hex
set number
setlocal number
setlocal numberwidth=4
setlocal omnifunc=
setlocal path=
setlocal nopreserveindent
setlocal nopreviewwindow
setlocal quoteescape=\\
setlocal noreadonly
setlocal norelativenumber
setlocal norightleft
setlocal rightleftcmd=search
setlocal noscrollbind
setlocal scrolloff=-1
setlocal shiftwidth=4
setlocal noshortname
setlocal sidescrolloff=-1
setlocal signcolumn=auto
setlocal nosmartindent
setlocal softtabstop=4
setlocal nospell
setlocal spellcapcheck=[.?!]\\_[\\])'\"\	\ ]\\+
setlocal spellfile=
setlocal spelllang=en
setlocal statusline=
setlocal suffixesadd=.lua
setlocal noswapfile
setlocal synmaxcol=3000
if &syntax != 'lua'
setlocal syntax=lua
endif
setlocal tabstop=8
setlocal tagcase=
setlocal tags=
setlocal termmode=
setlocal termwinkey=
setlocal termwinscroll=10000
setlocal termwinsize=
setlocal textwidth=0
setlocal thesaurus=
setlocal noundofile
setlocal undolevels=-123456
setlocal varsofttabstop=
setlocal vartabstop=
setlocal nowinfixheight
setlocal nowinfixwidth
setlocal wrap
setlocal wrapmargin=0
silent! normal! zE
let s:l = 75 - ((25 * winheight(0) + 30) / 61)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
75
normal! 0
wincmd w
exe 'vert 1resize ' . ((&columns * 118 + 118) / 237)
exe 'vert 2resize ' . ((&columns * 118 + 118) / 237)
tabnext 1
badd +117 ~/Documents/git/MyScripts/fusion_scripts/Scripts/Comp/bookmark_jump.py
badd +0 ~/Documents/git/MyScripts/fusion_scripts/Scripts/Comp/Rename_Plus.lua
if exists('s:wipebuf') && len(win_findbuf(s:wipebuf)) == 0
  silent exe 'bwipe ' . s:wipebuf
endif
unlet! s:wipebuf
set winheight=1 winwidth=20 shortmess=filnxtToOc
set winminheight=1 winminwidth=1
let s:sx = expand("<sfile>:p:r")."x.vim"
if file_readable(s:sx)
  exe "source " . fnameescape(s:sx)
endif
let &so = s:so_save | let &siso = s:siso_save
doautoall SessionLoadPost
unlet SessionLoad
" vim: set ft=vim :

let SessionLoad = 1
if &cp | set nocp | endif
let s:so_save = &so | let s:siso_save = &siso | set so=0 siso=0
let v:this_session=expand("<sfile>:p")
silent only
silent tabonly
cd ~\Documents\github\fusion_scripts\Scripts\Comp
if expand('%') == '' && !&modified && line('$') <= 1 && getline(1) == ''
  let s:wipebuf = bufnr('%')
endif
set shortmess=aoO
argglobal
%argdel
set stal=2
tabnew
tabrewind
edit ~\Documents\github\fusion_scripts\Scripts\Comp\UpdateSplittedLoaders.lua
set splitbelow splitright
set nosplitbelow
set nosplitright
wincmd t
set winminheight=0
set winheight=1
set winminwidth=0
set winwidth=1
argglobal
setlocal fdm=manual
setlocal fde=0
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=0
setlocal fml=1
setlocal fdn=20
setlocal fen
silent! normal! zE
let s:l = 15 - ((14 * winheight(0) + 16) / 33)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
15
normal! 05|
tabnext
edit ~\Documents\github\fusion_scripts\Scripts\Comp\ISDK_GridWarpTrack.lua
set splitbelow splitright
set nosplitbelow
set nosplitright
wincmd t
set winminheight=0
set winheight=1
set winminwidth=0
set winwidth=1
argglobal
setlocal fdm=manual
setlocal fde=0
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=0
setlocal fml=1
setlocal fdn=20
setlocal fen
silent! normal! zE
let s:l = 269 - ((4 * winheight(0) + 16) / 33)
if s:l < 1 | let s:l = 1 | endif
exe s:l
normal! zt
269
normal! 022|
tabnext 2
set stal=1
badd +1 ~\Documents\github\fusion_scripts\Scripts\Comp\ISDK_GridWarpTrack.lua
badd +0 ~\Documents\github\fusion_scripts\Scripts\Comp\UpdateSplittedLoaders.lua
badd +1 ~\Documents\github\fusion_scripts\Scripts\Comp\NERD_tree_1
badd +28 ~\Documents\github\fusion_scripts\Scripts\Comp\toolsXchange_v1.4.lua
badd +1 ~\Documents\github\fusion_scripts\Scripts\Comp\ToolXChange.lua
badd +13 ~\Documents\github\fusion_scripts\Scripts\Comp\alignXY.lua
badd +136 ~\_vimrc
badd +1 ~\[Plugins]
badd +3 ~\.bash_profile
badd +3 ~\NERD_tree_1
badd +1 ~\.vim_mru_files
badd +1 ~\Desktopgasp_lyricsnel_blu_it.txt
badd +1 ~\Desktopgasp_lyricsnel_blu_ru.txt
badd +13 ~\D:GitlabRTInstallReactorDeployScriptsCompToolbar16Toolbar16.lua
badd +1 ~\Documents\github\terminal\build\scripts\Create-AppxBundle.ps1
if exists('s:wipebuf') && len(win_findbuf(s:wipebuf)) == 0
  silent exe 'bwipe ' . s:wipebuf
endif
unlet! s:wipebuf
set winheight=1 winwidth=20 shortmess=filnxtToOSc
set winminheight=1 winminwidth=1
let s:sx = expand("<sfile>:p:r")."x.vim"
if file_readable(s:sx)
  exe "source " . fnameescape(s:sx)
endif
let &so = s:so_save | let &siso = s:siso_save
nohlsearch
doautoall SessionLoadPost
unlet SessionLoad
" vim: set ft=vim :

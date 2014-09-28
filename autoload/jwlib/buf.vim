" vim autoload file
" Filename:     buf.vim
" Maintainer:   janus_wel <janus.wel.3@gmail.com>
" License:      MIT License {{{1
"   See under URL.  Note that redistribution is permitted with LICENSE.
"   https://github.com/januswel/jwlib.vim/blob/master/LICENSE

" preparations {{{1
" reset the value of 'cpoptions' for portability
let s:save_cpoptions = &cpoptions
set cpoptions&vim

" main {{{1
" functions {{{2
function! jwlib#buf#IsEmpty() " {{{3
    if line('$') ==# 1 && empty(getline(1))
        return 1
    endif
    return 0
endfunction

function! jwlib#buf#IsModifiable() " {{{3
    if &modifiable && !&readonly
        return 1
    endif
    return 0
endfunction

function! jwlib#buf#IsNormalType() " {{{3
    if empty(&buftype)
        return 1
    endif
    return 0
endfunction

function! jwlib#buf#GetVisualHighlighted() " {{{3
    let save_reg_z = @z
    silent normal! gv"zy
    let result = @z
    let @z = save_reg_z

    return result
endfunction

function! jwlib#buf#SetVisualHighlighted(r) " {{{3
    normal! gv"_c=a:r
endfunction

" post-processings {{{1
" restore the value of 'cpoptions'
let &cpoptions = s:save_cpoptions
unlet s:save_cpoptions

" }}}1
" vim: ts=4 sw=4 sts=0 et fdm=marker fdc=3

" vim autoload file
" Filename:     shell.vim
" Maintainer:   janus_wel <janus.wel.3@gmail.com>
" License:      MIT License {{{1
"   See under URL.  Note that redistribution is permitted with LICENSE.
"   https://github.com/januswel/jwlib.vim/blob/master/LICENSE

" preparations {{{1
" reset the value of 'cpoptions' for portability
let s:save_cpoptions = &cpoptions
set cpoptions&vim

" main {{{1
" constants {{{2
" In this case, we can't use Dictionary for its attribute to exclude the order.
unlockvar s:shelltypes
let s:shelltypes = [
            \   ['cmd', '\vcmd%(\.exe)?'],
            \   ['csh', '\vt?csh%(\.exe)?'],
            \   ['zsh', '\vzsh%(\.exe)?'],
            \   ['sh',  '\v%(ba)?sh%(\.exe)?'],
            \ ]
lockvar s:shelltypes

" functions {{{2
function! jwlib#shell#GetType() " {{{3
    for [type, pattern] in s:shelltypes
        if &shell =~? pattern
            return type
        endif
    endfor

    " I don't know
    return
endfunction

function! jwlib#shell#GetEncoding(...) " {{{3
    " heuristic
    if jwlib#shell#GetType() ==# 'cmd'
        return 'cp932'
    endif

    " the term may know all
    if exists('&termencoding')
        if !empty(&termencoding) && &encoding !=? &termencoding
            return &termencoding
        endif
    endif

    " changing 'encoding' dynamically may have side effects
    if a:0 && a:1
        " the default value of 'encoding' is fitted with the system, maybe
        let save_encoding = &encoding
        set encoding&
        let result = &encoding
        let &encoding = save_encoding
        return result
    endif

    " I don't know
    return &encoding
endfunction

function! jwlib#shell#ShellFriendly(path) " {{{3
    let save_shellslash = &shellslash
    if jwlib#shell#GetType() ==# 'cmd'
        set noshellslash
    else
        set shellslash
    endif

    try
        let fullpath = fnamemodify(a:path, ':p')
        if has('multi_byte')
            let fullpath = iconv(
                    \   fullpath,
                    \   &encoding,
                    \   jwlib#shell#GetEncoding()
                    \ )
        endif
        return shellescape(fullpath)
    finally
        let &shellslash = save_shellslash
    endtry
endfunction

" post-processings {{{1
" restore the value of 'cpoptions'
let &cpoptions = s:save_cpoptions
unlet s:save_cpoptions

" }}}1
" vim: ts=4 sw=4 sts=0 et fdm=marker fdc=3

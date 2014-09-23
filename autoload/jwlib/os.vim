" vim autoload file
" Filename:     os.vim
" Maintainer:   janus_wel <janus.wel.3@gmail.com>
" Dependencies: {{{1 {{{1
"   This plugin requires following files
"
"   - http://github.com/januswel/jwlib.git
"       - autoload/jwlib/buf/shell.vim
" License:      MIT License {{{1
"   See under URL.  Note that redistribution is permitted with LICENSE.
"   https://github.com/januswel/jwlib.vim/blob/master/LICENSE

" preparations {{{1
" reset the value of 'cpoptions' for portability
let s:save_cpoptions = &cpoptions
set cpoptions&vim

" main {{{1
" constants {{{2
unlockvar s:opener
let s:opener = {
            \   'win32': 'start',
            \   'mac': 'open',
            \ }
lockvar s:opener

" functions {{{2
function! jwlib#os#GetOS() " {{{3
    if exists('s:os')
        return s:os
    endif

    if has('win32')
        let s:os = 'win32'
    elseif has('mac')
        let s:os = 'mac'
    else
        throw 'Unsuppoted OS'
    endif

    return s:os
endfunction

function! jwlib#os#Launch(path) " {{{3
    " launch specified path with the binded app on the OS
    let os = jwlib#os#GetOS()
    let command = '!' . s:opener[os] . ' ' . a:path
    silent execute command
endfunction


" post-processings {{{1
" restore the value of 'cpoptions'
let &cpoptions = s:save_cpoptions
unlet s:save_cpoptions

" }}}1
" vim: ts=4 sw=4 sts=0 et fdm=marker fdc=3

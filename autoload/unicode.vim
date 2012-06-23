" vim autoload file
" Filename:     unicode.vim
" Maintainer:   janus_wel <janus.wel.3@gmail.com>
" Dependency:
"   This script needs following files
"
"   autoload/jwlib/unicode/namelist.vim
"   https://github.com/januswel/jwlib/blob/master/autoload/unicode/namelist.vim
"
" Refer:
"   * http://d.hatena.ne.jp/krogue/20080616/1213590577
"   * http://homepage1.nifty.com/nomenclator/unicode/ucs_utf.htm
"
" License:      New BSD License {{{1
"   See under URL.  Note that redistribution is permitted with LICENSE.
"   http://github.com/januswel/dotfiles/vimfiles/LICENSE

" preparation {{{1
" check vim has the required feature
if !has('multi_byte')
    echoerr 'Vim does not have the required feature +multi_byte.'
    finish
endif

" reset the value of 'cpoptions' for portability
let s:save_cpoptions = &cpoptions
set cpoptions&vim

" main {{{1
" utilities {{{2
" like the normal command "g8"
function! jwlib#unicode#GetUtf8ByteSequenceStr(str)
    let utf8 = jwlib#unicode#GetUtf8ByteSequence(a:str)
    let result = []
    for byte in utf8
        call add(result, printf('%02x', byte))
    endfor
    return join(result)
endfunction

" patterns {{{3
" return the pattern in form of "\%x..", "\%u...." and "\%U........"
" see :help E678
function! jwlib#unicode#GetPattern(str, ...)
    if empty(a:000) || a:1 ==# 'x'
        " default and "\%x.."
        let result = []
        for byte in jwlib#unicode#GetUtf8ByteSequence(a:str)
            call add(result, printf('\%%x%02x', byte))
        endfor
        return join(result, '')
    elseif a:1 ==? 'u'
        " "\%u...." or "\%U........"
        let result = []
        for codepoint in jwlib#unicode#GetUnicodeCodePoint(a:str)
            if codepoint <= 0xffff
                call add(result, printf('\%%u%04x', codepoint))
            else
                call add(result, printf('\%%U%08x', codepoint))
            endif
        endfor
        return join(result, '')
    else
        echoerr 'Unknown argument: ' . string(a:1)
    endif
endfunction

" literals {{{3
" return the literal in form of "\x..", "\X..", "\u...." or "\U...."
" see :help expr-quote
" just delegate
function! jwlib#unicode#GetLiteral(str, ...)
    if empty(a:000)
        return s:GetTwoHexadecimalLiteral(a:str, 0)
    elseif a:1 ==# 'x'
        return s:GetTwoHexadecimalLiteral(a:str, 0)
    elseif a:1 ==# 'X'
        return s:GetTwoHexadecimalLiteral(a:str, 1)
    elseif a:1 ==# 'u'
        return s:GetFourHexadecimalLiteral(a:str, 0)
    elseif a:1 ==# 'U'
        return s:GetFourHexadecimalLiteral(a:str, 1)
    else
        echoerr 'Unknown argument: ' . string(a:1)
    endif
endfunction

" stuff
" "\x.." or "\X.."
function! s:GetTwoHexadecimalLiteral(str, case)
    let template = a:case ? '\X%02x' : '\x%02x'
    let result = []
    for byte in jwlib#unicode#GetUtf8ByteSequence(a:str)
        call add(result, printf(template, byte))
    endfor

    return join(result, '')
endfunction

" "\u...." or "\U...."
function! s:GetFourHexadecimalLiteral(str, case)
    let template = a:case ? '\U%04x' : '\u%04x'
    let result = []
    for codepoint in jwlib#unicode#GetUnicodeCodePoint(a:str)
        if codepoint <= 0xffff
            call add(result, printf(template, codepoint))
        else
            echoerr printf(
                \ "Can't convert to a literal in form \\u: %08x",
                \ codepoint)
        endif
    endfor

    return join(result, '')
endfunction

" about UTF-8 byte sequence {{{2
" just convert by iconv()
function! jwlib#unicode#GetUtf8ByteSequence(str)
    if empty(a:str)
        return [0]
    endif

    let bytes = iconv(a:str, &encoding, 'utf-8')
    let numof = strlen(bytes)
    let result = []
    let i = 0
    while i < numof
        call add(result, char2nr(bytes[i]))
        let i += 1
    endwhile

    return result
endfunction

" about Unicode code point {{{2
" functions {{{3
function! jwlib#unicode#GetUnicodeCodePoint(str)
    let utf8 = jwlib#unicode#GetUtf8ByteSequence(a:str)

    let result = []
    while !empty(utf8)
        let bytelength = s:GetByteLength(utf8[0])
        let sequence = remove(utf8, 0, bytelength - 1)
        call add(result, s:Convert2CodePoint(sequence))
    endwhile

    return result
endfunction

" return a byte length of a character
" in UTF-8, it is identified by checking the first byte
function! s:GetByteLength(byte)
    let bytelength = 1
    for [lower, upper] in s:condition_firstbyte
        if (lower <= a:byte) && (a:byte <= upper)
            return bytelength
        endif
        let bytelength += 1
    endfor

    throw 'Unsupposed byte: ' . string(a:byte)
endfunction

" inverse transform from UTF-8 byte sequence to Unicode code point
function! s:Convert2CodePoint(utf8)
    " the condition is determined by a number of byte sequence
    let idx = len(a:utf8) - 1
    let conditions = s:conditions[idx]

    " check if the byte sequence is valid or not
    for condition in conditions
        let i = 0
        for [lower, upper] in condition
            let byte = a:utf8[i]
            if (lower <= byte) || (byte <= upper)
                return s:funcs[idx](a:utf8)
            endif
            let i += 1
        endfor
    endfor

    throw 'Found the malformed utf-8 byte sequence: ' . string(a:utf8)
endfunction

" stuff functions {{{3
function! s:OneByteToUnicode(utf8)
    " 0xxxxxxx -> 00000000-0xxxxxxx
    return a:utf8[0]
endfunction
function! s:TwoBytesToUnicode(utf8)
    " 110xxxxx 10yyyyyy -> 00000xxx-xxyyyyyy
    return  s:RS(s:LS(a:utf8[0], 0x08), 0x20) * 0x0100
        \ + s:LS(a:utf8[0], 0x40) + s:RS(s:LS(a:utf8[1], 0x04), 0x04)
endfunction
function! s:ThreeBytesToUnicode(utf8)
    " 1110xxxx 10yyyyyy 10zzzzzz -> xxxxyyyy-yyzzzzzz
    return  (s:LS(a:utf8[0], 0x10) + s:RS(s:LS(a:utf8[1], 0x04), 0x10)) * 0x0100
        \ +  s:LS(a:utf8[1], 0x40) + s:RS(s:LS(a:utf8[2], 0x04), 0x04)
endfunction
function! s:FourBytesToUnicode(utf8)
    " 11110www 10xxxxxx 10yyyyyy 10zzzzzz -> 00000000-000wwwxx-xxxxyyyy-yyzzzzzzz
    return  (s:RS(s:LS(a:utf8[0], 0x20), 0x08) + s:RS(s:LS(a:utf8[1], 0x04), 0x40)) * 0x010000
        \ + (s:LS(a:utf8[1], 0x10) + s:RS(s:LS(a:utf8[2], 0x04), 0x10)) * 0x0100
        \ +  s:LS(a:utf8[1], 0x40) + s:RS(s:LS(a:utf8[2], 0x04), 0x04)
endfunction

" left shift (8 bits)
function! s:LS(nr, bits)
    return a:nr * a:bits % 0x0100
endfunction
" right shift
function! s:RS(nr, bits)
    return a:nr / a:bits
endfunction

" a number of bytes of UTF-8 character is identified by the first byte
" the function to build from s:conditions
function! s:BuildFirstByteConditions(src)
    let result = []
    for bytelength in a:src
        for conditions in bytelength
            if !exists('lower')
                let lower = conditions[0][0]
            endif
            let upper = conditions[0][1]
        endfor
        call add(result, [lower, upper])
        unlet lower
    endfor

    return result
endfunction

" constants {{{3
" the List that has Funcrefs to calculate Unicode code point
unlockvar s:funcs
let s:funcs = [
            \   function('s:OneByteToUnicode'),
            \   function('s:TwoBytesToUnicode'),
            \   function('s:ThreeBytesToUnicode'),
            \   function('s:FourBytesToUnicode'),
            \ ]
lockvar s:funcs

" conditions that be used to check if the byte sequence are valid or not
unlockvar s:conditions
let s:conditions = [
            \   [[[0, 0x7f]]],
            \   [[[0xc2, 0xdf], [0x80, 0xbf]]],
            \   [
            \       [[0xe0, 0xe0], [0xa0, 0xbf], [0x80, 0xbf]],
            \       [[0xe1, 0xec], [0x80, 0xbf], [0x80, 0xbf]],
            \       [[0xed, 0xed], [0x80, 0x9f], [0x80, 0xbf]],
            \       [[0xee, 0xef], [0x80, 0xbf], [0x80, 0xbf]],
            \   ],
            \   [
            \       [[0xf0, 0xf0], [0x90, 0xbf], [0x80, 0xbf], [0x80, 0xbf]],
            \       [[0xf1, 0xf3], [0x80, 0xbf], [0x80, 0xbf], [0x80, 0xbf]],
            \       [[0xf4, 0xf4], [0x80, 0x8f], [0x80, 0xbf], [0x80, 0xbf]],
            \   ],
            \ ]
lockvar s:conditions

unlockvar s:condition_firstbyte
let s:condition_firstbyte = s:BuildFirstByteConditions(s:conditions)
lockvar s:condition_firstbyte

" about Unicode character names {{{2
function! jwlib#unicode#GetName(char)
    let codepoint =
                \ printf('%04X', jwlib#unicode#GetUnicodeCodePoint(a:char)[0])
    return get(g:jwlib#unicode#namelist#dict, codepoint, '')
endfunction


" post-processing {{{1
" restore the value of 'cpoptions'
let &cpoptions = s:save_cpoptions
unlet s:save_cpoptions

" }}}1
" vim: ts=4 sw=4 sts=0 et fdm=marker fdc=4

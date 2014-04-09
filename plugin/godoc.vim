" Copyright 2011 The Go Authors. All rights reserved.
" Use of this source code is governed by a BSD-style
" license that can be found in the LICENSE file.
"
" godoc.vim: Vim command to see godoc.
"
"
" Commands:
"
"   :GoDoc
"
"       Open the relevant Godoc for either the word[s] passed to the command or
"       the, by default, the word under the cursor.
"
" Options:
"
"   g:go_godoc_commands [default=1]
"
"       Flag to indicate whether to enable the commands listed above.

if exists("g:loaded_godoc")
    finish
endif
let g:loaded_godoc = 1

let s:buf_nr = -1

if !exists('g:go_godoc_commands')
    let g:go_godoc_commands = 1
endif

if g:go_godoc_commands
    command! -nargs=* -range -complete=customlist,go#package#Complete GoDoc :call s:Godoc('leftabove new', <f-args>)
endif

nnoremap <silent> <Plug>(go-doc) :<C-u>call <SID>Godoc("leftabove new")<CR>
nnoremap <silent> <Plug>(go-doc-tab) :<C-u>call <SID>Godoc("tabnew")<CR>
nnoremap <silent> <Plug>(go-doc-vertical) :<C-u>call <SID>Godoc("vnew")<CR>
nnoremap <silent> <Plug>(go-doc-split) :<C-u>call <SID>Godoc("split")<CR>

function! s:Godoc(mode, ...)
    if !executable('godoc')
        echohl WarningMsg
        echo "godoc command not found."
        echo "  install with: go get code.google.com/p/go.tools/cmd/godoc"
        echohl None
        return -1
    endif

    if !len(a:000)
        let oldiskeyword = &iskeyword
        setlocal iskeyword+=.
        let word = expand('<cword>')
        let &iskeyword = oldiskeyword
        let word = substitute(word, '[^a-zA-Z0-9\\/._~-]', '', 'g')
        let words = split(word, '\.\ze[^./]\+$')
    else
        let words = a:000
    endif

    if !len(words)
        return
    endif

    let pkg = words[0]
    let packages = GoImports() 

    if has_key(packages, pkg)
        let command = 'godoc ' . packages[pkg]
    else
        let command = 'godoc ' . pkg
    endif

    silent! let content = system(command)
    if v:shell_error || !len(content)
        echo 'No documentation found for "' . pkg . '".'
        return -1
    endif

    call s:GodocView(a:mode, content)

    if len(words) < 2
        return
        echo 'No documentation found for "' . pkg . '".'
    endif 

    if search('^\%(const\|var\|type\|\s\+\) ' . pkg . '\s\+=\s')
        silent! normal zt
        return -1
    endif

    if search('^func ' . words[1] . '(')
        silent! normal zt
        return -1
    endif

endfunction

function! s:GodocView(position, content)
    if !bufexists(s:buf_nr)
        exe a:position
        file `="[Godoc]"`
        let s:buf_nr = bufnr('%')
    elseif bufwinnr(s:buf_nr) == -1
        exe a:position
        execute s:buf_nr . 'buffer'
    elseif bufwinnr(s:buf_nr) != bufwinnr('%')
        execute bufwinnr(s:buf_nr) . 'wincmd w'
    endif

    setlocal filetype=godoc
    setlocal bufhidden=delete
    setlocal buftype=nofile
    setlocal noswapfile
    setlocal nobuflisted
    setlocal nocursorline
    setlocal nocursorcolumn
    setlocal iskeyword+=:
    setlocal iskeyword-=-

    setlocal modifiable
    %delete _ 
    call append(0, split(a:content, "\n"))
    $delete _ 
    setlocal nomodifiable
endfunction


" vim:ts=4:sw=4:et

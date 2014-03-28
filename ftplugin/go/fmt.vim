" Copyright 2011 The Go Authors. All rights reserved.
" Use of this source code is governed by a BSD-style
" license that can be found in the LICENSE file.
"
" fmt.vim: Vim command to format Go files with gofmt.
"
" This filetype plugin add a new commands for go buffers:
"
"   :Fmt
"
"       Filter the current Go buffer through gofmt.
"       It tries to preserve cursor position and avoids
"       replacing the buffer with stderr output.
"
" Options:
"
"   g:go_fmt_commands [default=1]
"
"       Flag to indicate whether to enable the commands listed above.
"
"   g:go_fmt_command [default="gofmt"]
"
"       Flag naming the gofmt executable to use.
"
"   g:go_fmt_autosave [default=1]
"
"       Flag to auto call :Fmt when saved file
"
if exists("b:did_ftplugin_go_fmt")
    finish
endif

if !exists("g:go_fmt_commands")
    let g:go_fmt_commands = 1
endif

if !exists("g:go_fmt_command")
    let g:go_fmt_command = "goimports"
endif

if !exists('g:go_fmt_autosave')
    let g:go_fmt_autosave = 1
endif

if g:go_fmt_autosave
    autocmd BufWritePre <buffer> :Fmt
endif

if g:go_fmt_commands
    command! -buffer Fmt call s:GoFormat()
endif


"  modified and improved version, doesn't undo changes and break undo history
"  - fatih 2014
function! s:GoFormat()
    let l:curw=winsaveview()
    let l:tmpname=tempname()
    call writefile(getline(1,'$'), l:tmpname)
    let out = system(g:go_fmt_command . " " . l:tmpname)

    "if there is no error on the temp file, gofmt our original file
    if v:shell_error == 0
        try | silent undojoin | catch | endtry
        silent execute "%!" . g:go_fmt_command
        call setqflist([]) 
    else
        "otherwise get the errors and put them to quickfix window
        let errors = []
        for line in split(out, '\n')
            let tokens = matchlist(line, '^\(.\{-}\):\(\d\+\):\(\d\+\)\s*\(.*\)')
            if !empty(tokens)
                call add(errors, {"filename": @%,
                                 \"lnum":     tokens[2],
                                 \"col":      tokens[3],
                                 \"text":     tokens[4]})
            endif
        endfor
        if empty(errors)
            % | " Couldn't detect gofmt error format, output errors
        endif
        if !empty(errors)
            call setqflist(errors, 'r')
        endif
        echohl Error | echomsg "Gofmt returned error" | echohl None
    endif
    call delete(l:tmpname)
    call winrestview(l:curw)
    cwindow
endfunction

let b:did_ftplugin_go_fmt = 1

" vim:ts=4:sw=4:et

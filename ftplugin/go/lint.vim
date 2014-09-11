" Copyright 2013 The Go Authors. All rights reserved.
" Use of this source code is governed by a BSD-style
" license that can be found in the LICENSE file.
"
" lint.vim: Vim command to lint Go files with golint.
"
"   https://github.com/golang/lint
"
" This filetype plugin add a new commands for go buffers:
"
"   :GoLint
"
"       Run golint for the current Go file.
"
if exists("b:did_ftplugin_go_lint")
    finish
endif

if !exists("g:go_golint_bin")
    finish
endif

command! -buffer GoLint call s:GoLint()

function! s:GoLint() abort
    if go#tool#BinExists(g:go_golint_bin) == -1 | return | endif
    silent cexpr system(g:go_golint_bin . " " . shellescape(expand('%')))
    cwindow
endfunction

let b:did_ftplugin_go_lint = 1

" vim:ts=4:sw=4:et

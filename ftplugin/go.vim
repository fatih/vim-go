" Copyright 2013 The Go Authors. All rights reserved.
" Use of this source code is governed by a BSD-style
" license that can be found in the LICENSE file.
"
" go.vim: Vim filetype plugin for Go.

if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1

if !exists("g:go_auto_type_info")
    let g:go_auto_type_info = 0
endif


setlocal comments=s1:/*,mb:*,ex:*/,://
setlocal commentstring=//\ %s

setlocal noexpandtab

let b:undo_ftplugin = "setl com< cms<"

" Set gocode completion
setlocal omnifunc=go#complete#Complete

" GoInfo automatic update
if g:go_auto_type_info != 0
    setlocal updatetime=300
    au! CursorHold *.go nested call go#complete#Info()
endif

compiler go

" vim:ts=4:sw=4:et

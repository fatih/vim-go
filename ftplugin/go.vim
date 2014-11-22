" Copyright 2013 The Go Authors. All rights reserved.
" Use of this source code is governed by a BSD-style
" license that can be found in the LICENSE file.
"
" go.vim: Vim filetype plugin for Go.

if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1

let b:undo_ftplugin = "setl fo< com< cms<"

setlocal formatoptions-=t

setlocal comments=s1:/*,mb:*,ex:*/,://
setlocal commentstring=//\ %s

setlocal noexpandtab

compiler go

" Set gocode completion
setlocal omnifunc=go#complete#Complete

if get(g:, "go_doc_keywordprg_enabled", 1)
    " keywordprg doesn't allow to use vim commands, override it
    nnoremap <buffer> <silent> K :GoDoc<cr>
endif

if get(g:, "go_def_mapping_enabled", 1)
   nnoremap <buffer> <silent> gd :GoDef<cr>
endif

augroup vim-go
    autocmd!

    " GoInfo automatic update
    if get(g:, "go_auto_type_info", 0)
        setlocal updatetime=300
        autocmd CursorHold *.go nested call go#complete#Info()
    endif

    " code formatting on save
    if get(g:, "go_fmt_autosave", 1)
        autocmd BufWritePre <buffer> call go#fmt#Format(-1)
    endif

augroup END

" vim:ts=4:sw=4:et

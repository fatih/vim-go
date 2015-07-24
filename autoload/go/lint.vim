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
"   :GoLint [options]
"
"       Run golint for the current Go file.
"
if !exists("g:go_golint_bin")
    let g:go_golint_bin = "golint"
endif

function! go#lint#Run(...) abort
	let bin_path = go#path#CheckBinPath(g:go_golint_bin) 
	if empty(bin_path) 
		return 
	endif

    if a:0 == 0
        let goargs = shellescape(expand('%'))
    else
        let goargs = go#util#Shelljoin(a:000)
    endif
    silent cexpr system(bin_path . " " . goargs)
    cwindow
endfunction


" vim:ts=4:sw=4:et

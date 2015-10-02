if !exists("g:go_metalinter_command")
    let g:go_metalinter_command = ""
endif

if !exists("g:go_metalinter_enabled")
    let g:go_metalinter_enabled = ['vet', 'golint', 'errcheck']
endif

if !exists("g:go_metalinter_path")
    let g:go_metalinter_path = "./..."
endif

if !exists("g:go_golint_bin")
    let g:go_golint_bin = "golint"
endif

if !exists("g:go_errcheck_bin")
    let g:go_errcheck_bin = "errcheck"
endif

function! go#lint#Gometa(path_to_lint) abort
    let meta_command = "gometalinter --disable-all"
    if empty(g:go_metalinter_command)
        let bin_path = go#path#CheckBinPath("gometalinter") 
        if empty(bin_path) 
            return 
        endif

        if empty(g:go_metalinter_enabled)
            echohl Error | echomsg "vim-go: please enable linters with the setting g:go_metalinter_enabled" | echohl None
            return 
        endif

        for linter in g:go_metalinter_enabled
            let meta_command .= " --enable=".linter
        endfor


        " by default we search for all underlying files
        let path = g:go_metalinter_path
        if !empty(a:path_to_lint)
            let path = a:path_to_lint
        endif

        let meta_command .=  " " . path
    else
        " the user wants something else, let us use it.
        let meta_command = g:go_metalinter_command
    endif

    " comment out the following two lines for debugging
    " echo meta_command
    " return

    let out = go#tool#ExecuteInDir(meta_command)

    if v:shell_error == 0
        redraw | echo
        call setqflist([])
        echon "vim-go: " | echohl Function | echon "[metalinter] PASS" | echohl None
    else
        " backup users errorformat, will be restored once we are finished
        let old_errorformat = &errorformat

        " GoMetaLinter can output one of the two, so we look for both of them
        "   <file>:<line>:[<column>]: <message> (<linter>)
        "   <file>:<line>:: <message> (<linter>)
        let &errorformat = "%f:%l:%c:%t%*[^:]:\ %m,%f:%l::%t%*[^:]:\ %m"

        " create the quickfix list and open it
        cgetexpr split(out, "\n")
        cwindow

        let &errorformat = old_errorformat
    endif
endfunction

" Golint calls 'golint' on the current directory. Any warnings are populated in
" the quickfix window
function! go#lint#Golint(...) abort
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

" Vet calls 'go vet' on the current directory. Any warnings are populated in
" the quickfix window
function! go#lint#Vet(bang, ...)
    call go#cmd#autowrite()
    echon "vim-go: " | echohl Identifier | echon "calling vet..." | echohl None
    if a:0 == 0
        let out = go#tool#ExecuteInDir('go vet')
    else
        let out = go#tool#ExecuteInDir('go tool vet ' . go#util#Shelljoin(a:000))
    endif
    if v:shell_error
        call go#tool#ShowErrors(out)
    else
        call setqflist([])
    endif

    cwindow
    let errors = getqflist()
    if !empty(errors) 
        if !a:bang
            cc 1 "jump to first error if there is any
        endif
    else
        redraw | echon "vim-go: " | echohl Function | echon "[vet] PASS" | echohl None
    endif
endfunction

" ErrCheck calls 'errcheck' for the given packages. Any warnings are populated in
" the quickfix window.
function! go#lint#Errcheck(...) abort
    if a:0 == 0
        let goargs = go#package#ImportPath(expand('%:p:h'))
        if goargs == -1
            echohl Error | echomsg "vim-go: package is not inside GOPATH src" | echohl None
            return
        endif
    else
        let goargs = go#util#Shelljoin(a:000)
    endif

    let bin_path = go#path#CheckBinPath(g:go_errcheck_bin)
    if empty(bin_path)
        return
    endif

    echon "vim-go: " | echohl Identifier | echon "errcheck analysing ..." | echohl None
    redraw

    let command = bin_path . ' ' . goargs
    let out = go#tool#ExecuteInDir(command)

    if v:shell_error
        let errors = []
        let mx = '^\(.\{-}\):\(\d\+\):\(\d\+\)\s*\(.*\)'
        for line in split(out, '\n')
            let tokens = matchlist(line, mx)
            if !empty(tokens)
                call add(errors, {"filename": expand(go#path#Default() . "/src/" . tokens[1]),
                            \"lnum": tokens[2],
                            \"col": tokens[3],
                            \"text": tokens[4]})
            endif
        endfor

        if empty(errors)
            echohl Error | echomsg "GoErrCheck returned error" | echohl None
            echo out
        endif

        if !empty(errors)
            redraw | echo
            call setqflist(errors, 'r')
        endif
    else
        redraw | echo
        call setqflist([])
        echon "vim-go: " | echohl Function | echon "[errcheck] PASS" | echohl None
    endif

    cwindow
endfunction

" vim:ts=4:sw=4:et

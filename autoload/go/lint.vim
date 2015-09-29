if !exists("g:go_metalinter_command")
    let g:go_metalinter_command = ""
endif

if !exists("g:go_metalinter_allowed")
    let g:go_metalinter_allowed = ['vet', 'golint', 'errcheck']
endif

if !exists("g:go_golint_bin")
    let g:go_golint_bin = "golint"
endif

if !exists("g:go_errcheck_bin")
    let g:go_errcheck_bin = "errcheck"
endif

function! go#lint#Gometa(...) abort
    " change GOPATH too, so the underlying tools in gometalinter can pick up
    " the correct GOPATH
    let old_gopath = $GOPATH
    let $GOPATH = go#path#Detect()

    let meta_command = "gometalinter --disable-all"
    if empty(g:go_metalinter_command)
        let bin_path = go#path#CheckBinPath("gometalinter") 
        if empty(bin_path) 
            return 
        endif

        for linter in g:go_metalinter_allowed
            let meta_command .= " --enable=".linter
        endfor

        " TODO(arslan): maybe this should be passed via argument?
        " for now we search for all underlying files
        let meta_command .=  " ./..."
    else
        " the user wants something else, let us use it.
        let meta_command = g:go_metalinter_command
    endif

    " debug
    " echo meta_command
    " return

    let out = system(meta_command)
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

    " restore GOPATH again
    let $GOPATH = old_gopath
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
function! go#cmd#Vet(bang, ...)
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

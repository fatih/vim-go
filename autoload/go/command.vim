function! go#command#Run(bang, ...)
    let default_makeprg = &makeprg
    if !len(a:000)
        let &makeprg = "go run " . join(go#tool#Files(), ' ')
    else
        let &makeprg = "go run " . expand(a:1)
    endif

    exe 'make!'
    if !a:bang
        cwindow
    endif

    let &makeprg = default_makeprg
endfunction

function! go#command#Install(...)
    let pkgs = join(a:000, ' ')
    let command = 'go install '.pkgs
    let out = s:execute_in_current_dir(command)
    if v:shell_error
        call go#tool#ShowErrors(out)
        cwindow
        return
    endif

    if exists("$GOBIN")
        echo "Installed to ".$GOBIN
    else
        echo "Installed to ".$GOPATH/bin
    endif
endfunction

function! go#command#Build(bang)
    let default_makeprg = &makeprg
    let gofiles = join(go#tool#Files(), ' ')
    if v:shell_error
        let &makeprg = "go build . errors"
    else
        let &makeprg = "go build -o /dev/null " . gofiles
    endif

    exe 'make!'
    if !a:bang
        cwindow
    endif

    let &makeprg = default_makeprg
endfunction

function! go#command#Test()
    let command = "go test ."
    let out = s:execute_in_current_dir(command)
    if v:shell_error
        call go#tool#ShowErrors(out)
    else
        call setqflist([])
    endif
    cwindow
endfunction

function! go#command#Vet()
    let out = s:execute_in_current_dir('go vet')
    let errors = []
    for line in split(out, '\n')
        let tokens = matchlist(line, '^\(.\{-}\):\(\d\+\):\s*\(.*\)')
        if !empty(tokens)
            call add(errors, {"filename": @%,
                        \"lnum":     tokens[2],
                        \"text":     tokens[3]})
        endif
    endfor
    if !empty(errors)
        call setqflist(errors, 'r')
    endif
    cwindow
endfunction

function! s:execute_in_current_dir(cmd) abort
    let cd = exists('*haslocaldir') && haslocaldir() ? 'lcd ' : 'cd '
    let dir = getcwd()
    try
        execute cd.'`=expand("%:p:h")`'
        let out = system(a:cmd)
    finally
        execute cd.'`=dir`'
    endtry
    return out
endfunction

" vim:ts=4:sw=4:et

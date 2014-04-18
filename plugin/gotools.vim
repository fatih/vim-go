if exists("g:go_loaded_gotools")
    finish
endif
let g:go_loaded_gotools = 1

function! s:GoRun(bang, ...)
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

function! s:GoInstall(...)
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

function! s:GoBuild(bang)
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

function! s:GoTest()
    let command = "go test ."
    let out = s:execute_in_current_dir(command)
    if v:shell_error
        call go#tool#ShowErrors(out)
    else
        call setqflist([])
    endif
    cwindow
endfunction

function! s:GoVet()
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

" Execute the command with system() in the current files directory instead of
" in current directory. Returns  the result.
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


if !hasmapto('<Plug>(go-run)')
    nnoremap <silent> <Plug>(go-run) :<C-u>call <SID>GoRun(expand('%'))<CR>
endif

if !hasmapto('<Plug>(go-build)')
    nnoremap <silent> <Plug>(go-build) :<C-u>call <SID>GoBuild('')<CR>
endif

if !hasmapto('<Plug>(go-install)')
    nnoremap <silent> <Plug>(go-install) :<C-u>call <SID>GoInstall()<CR>
endif

if !hasmapto('<Plug>(go-test)')
    nnoremap <silent> <Plug>(go-test) :<C-u>call <SID>GoTest()<CR>
endif

if !hasmapto('<Plug>(go-vet)')
    nnoremap <silent> <Plug>(go-vet) :<C-u>call <SID>GoVet()<CR>
endif

if !hasmapto('<Plug>(go-files)')
    nnoremap <silent> <Plug>(go-files) :<C-u>call <SID>go#tool#Files()<CR>
endif

if !hasmapto('<Plug>(go-deps)')
    nnoremap <silent> <Plug>(go-deps) :<C-u>call <SID>go#tool#Deps()<CR>
endif

" This needs to be here, it doesn't get sourced when put into a file under ftplugin/go
if !hasmapto('<Plug>(go-import)')
    nnoremap <silent> <Plug>(go-import) :<C-u>call GoSwitchImport(1, '', expand('<cword>'))<CR>
endif



command! -nargs=0 GoFiles echo go#tool#Files()
command! -nargs=0 GoDeps echo go#tool#Deps()

command! -nargs=* -range -bang GoRun call s:GoRun(<bang>0,<f-args>)
command! -nargs=? -range -bang GoBuild call s:GoBuild(<bang>0)

command! -nargs=* GoInstall call s:GoInstall(<f-args>)
command! -nargs=0 GoTest call s:GoTest()
command! -nargs=0 GoVet call s:GoVet()

" vim:ts=4:sw=4:et

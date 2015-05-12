if !exists("g:go_jump_to_error")
    let g:go_jump_to_error = 1
endif

" Build builds the project with 'gb build' and the passed arguments to it
function! go#gb#Build(...)
    let command = 'gb build '
    if len(a:000)
        let pkgs = join(a:000, ' ')
        let command = 'gb build ' . pkgs
    endif

    echon "vim-go: " | echohl Identifier | echon "building ..."| echohl None
    let out = go#tool#ExecuteInDir(command)
    if v:shell_error
        call go#tool#ShowErrors(out)
        cwindow
        let errors = getqflist()
        if !empty(errors)
            if g:go_jump_to_error
                cc 1 "jump to first error if there is any
            endif
        endif
        return
    endif

    redraws! | echon "vim-go: " | echohl Function | echon "[gb build] SUCCESS"| echohl None
endfunction

" BuildAll builds the project with 'gb build all'
function! go#gb#BuildAll()
    return go#gb#Build("all")
endfunction

" vim:ts=4:sw=4:et

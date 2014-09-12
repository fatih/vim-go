if exists("g:go_loaded_errcheck") 
    finish
endif
let g:go_loaded_errcheck = 1

if !exists("g:go_errcheck_bin")
    let g:go_errcheck_bin = "errcheck"
endif

command! GoErrCheck call s:ErrCheck()

function! s:ErrCheck() abort
    if go#tool#BinExists(g:go_errcheck_bin) == -1 | return | endif
    let out = system(g:go_errcheck_bin . ' ' . shellescape(expand('%:p:h')))
    if v:shell_error
        let errors = []
        let mx = '^\(.\{-}\):\(\d\+\):\(\d\+\)\s*\(.*\)'
        for line in split(out, '\n')
            let tokens = matchlist(line, mx)

            if !empty(tokens)
                call add(errors, {"filename": tokens[1],
                            \"lnum": tokens[2],
                            \"col": tokens[3],
                            \"text": tokens[4]})
            endif
        endfor
        if empty(errors)
            % | " Couldn't detect error format, output errors
        endif
        if !empty(errors)
            call setqflist(errors, 'r')
        endif
        echohl Error | echomsg "GoErrCheck returned error" | echohl None
    else
        call setqflist([])
    endif
    cwindow
endfunction


" vim:ts=4:sw=4:et

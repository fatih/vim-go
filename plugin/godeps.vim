if exists("g:go_loaded_godeps")
  finish
endif
let g:go_loaded_godeps = 1

function! g:GoFiles() 
    let out=system("go list -f $'{{range $f := .GoFiles}}{{$.Dir}}/{{$f}}\n{{end}}'")
    return out
endfunction

function! g:GoFiles() 
    let out=system("go list -f $'{{range $f := .GoFiles}}{{$.Dir}}/{{$f}}\n{{end}}'")
    return out
endfunction

function! s:GoDeps() 
    let out=system("go list -f $'{{range $f := .Deps}}{{$f}}\n{{end}}'")
    return out
endfunction

function! s:GoRun() 
    exec "!go run " . join(split(g:GoFiles(), '\n'), ' ')
endfunction

function! s:GoTest() 
    let out = system("go test .")
    if v:shell_error
        "otherwise get the errors and put them to quickfix window
        let errors = []
        for line in split(out, '\n')
            let tokens = matchlist(line, '^\(.\{-}\):\(\d\+\):\s*\(.*\)')
            if !empty(tokens)
                call add(errors, {"filename": @%,
                                 \"lnum":     tokens[2],
                                 \"text":     tokens[3]})
            endif
        endfor
        if empty(errors)
            % | " Couldn't detect gofmt error format, output errors
        endif
        if !empty(errors)
            call setqflist(errors, 'r')
        endif
        echohl Error | echomsg "Go test returned error" | echohl None
    endif  
 
endfunction

command! Gofiles echo g:GoFiles()
command! Godeps echo s:GoDeps()
command! Gorun call s:GoRun()
command! Gotest call s:GoTest()

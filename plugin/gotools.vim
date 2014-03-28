if exists("g:go_loaded_gotools")
  finish
endif
let g:go_loaded_gotools = 1

function! GoFiles() 
    let out=system("go list -f $'{{range $f := .GoFiles}}{{$.Dir}}/{{$f}}\n{{end}}'")
    return out
endfunction

function! s:GoDeps() 
    let out=system("go list -f $'{{range $f := .Deps}}{{$f}}\n{{end}}'")
    return out
endfunction

function! s:GoRun(...) 
    if !len(a:000)
      exec "!go run " . join(split(GoFiles(), '\n'), ' ')
    else
      exec "!go run " . expand(a:1)
    endif
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
    else
        call setqflist([]) 
    endif  
    cwindow
endfunction

command! Gofiles echo GoFiles()
command! Godeps echo s:GoDeps()
command! Gotest call s:GoTest()

command! -nargs=* -range Gorun call s:GoRun(<f-args>)

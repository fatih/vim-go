if exists("g:go_loaded_godeps")
  finish
endif
let g:go_loaded_godeps = 1

function! GoFiles() 
    let out=system("go list -f $'{{range $f := .GoFiles}}{{$.Dir}}/{{$f}}\n{{end}}'")
    return out
endfunction

function! GoDeps() 
    let out=system("go list -f $'{{range $f := .Deps}}{{$f}}\n{{end}}'")
    return out
endfunction

function! GoRun() 
    exec "!go run " . join(split(GoFiles(), '\n'), ' ')
endfunction

command! -buffer Gofiles echo GoFiles()
command! -buffer Godeps echo GoDeps()
command! -buffer Gorun call GoRun()

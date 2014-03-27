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

command! Gofiles echo GoFiles()
command! Godeps echo GoDeps()

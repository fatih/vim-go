if exists("g:go_loaded_godeps")
  finish
endif
let g:go_loaded_godeps = 1

function! GoFiles() 
    let out=system("go list -f $'{{range $f := .GoFiles}}{{$.Dir}}/{{$f}}\n{{end}}'")
    echo out
endfunction

function! GoDeps() 
    let out=system("go list -f $'{{range $f := .Deps}}{{$f}}\n{{end}}'")
    echo out
endfunction

command! Gofiles :call GoFiles()
command! Godeps :call GoDeps()

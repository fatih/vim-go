function! go#tool#Files()
    let command = "go list -f $'{{range $f := .GoFiles}}{{$.Dir}}/{{$f}}\n{{end}}'"
    let out = go#tool#ExecuteInDir(command)
    return split(out, '\n')
endfunction

function! go#tool#Deps()
    let command = "go list -f $'{{range $f := .Deps}}{{$f}}\n{{end}}'"
    let out = go#tool#ExecuteInDir(command)
    return split(out, '\n')
endfunction

function! go#tool#Imports()
    let imports = {}
    let command = "go list -f $'{{range $f := .Imports}}{{$f}}\n{{end}}'"
    let out = go#tool#ExecuteInDir(command)
    if v:shell_error
        echo out
        return imports
    endif

    for package_path in split(out, '\n')
        let package_name = fnamemodify(package_path, ":t")
        let imports[package_name] = package_path
    endfor

    return imports
endfunction

function! go#tool#ShowErrors(out)
    let errors = []
    for line in split(a:out, '\n')
        let tokens = matchlist(line, '^\s*\(.\{-}\):\(\d\+\):\s*\(.*\)')
        if !empty(tokens)
            call add(errors, {"filename" : expand("%:p:h:") . "/" . tokens[1],
                        \"lnum":     tokens[2],
                        \"text":     tokens[3]})
        elseif !empty(errors)
            " Preserve indented lines.
            " This comes up especially with multi-line test output.
            if match(line, '^\s') >= 0
                call add(errors, {"text": line})
            endif
        endif
    endfor

    if !empty(errors)
        call setqflist(errors, 'r')
        return
    endif

    if empty(errors)
        " Couldn't detect error format, output errors
        echo a:out
    endif
endfunction

function! go#tool#ExecuteInDir(cmd) abort
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

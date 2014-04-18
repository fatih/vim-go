function! go#tool#Files()
	let command = "go list -f $'{{range $f := .GoFiles}}{{$.Dir}}/{{$f}}\n{{end}}'"
	let out = s:execute_in_current_dir(command)
    return split(out, '\n')
endfunction

function! go#tool#Deps()
	let command = "go list -f $'{{range $f := .Deps}}{{$f}}\n{{end}}'"
	let out = s:execute_in_current_dir(command)
    return split(out, '\n')
endfunction

function! go#tool#Imports()
	let imports = {}
	let command = "go list -f $'{{range $f := .Imports}}{{$f}}\n{{end}}'"
	let out = s:execute_in_current_dir(command)
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
        let tokens = matchlist(line, '^\(.\{-}\):\(\d\+\):\s*\(.*\)')
        if !empty(tokens)
            call add(errors, {"filename": @%,
                        \"lnum":     tokens[2],
                        \"text":     tokens[3]})
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

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
        let root_path = s:findProjectRoot()
        if empty(root_path)
              redraws! | echon "vim-go: [run] " | echohl ErrorMsg | echon "[gb build] PROJECT root not found"| echohl None
            return
        endif

        let cd = exists('*haslocaldir') && haslocaldir() ? 'lcd ' : 'cd '
        let current_dir = getcwd()
        execute cd . fnameescape(root_path)

        call go#tool#ShowErrors(out, 0)
        cwindow
        let errors = getqflist()
        if !empty(errors)
            if g:go_jump_to_error
                cc 1 "jump to first error if there is any
            endif
        endif

        execute cd . fnameescape(current_dir)
        return
    endif

    redraws! | echon "vim-go: " | echohl Function | echon "[gb build] SUCCESS"| echohl None
endfunction

" BuildAll builds the project with 'gb build all'
function! go#gb#BuildAll()
    return go#gb#Build("all")
endfunction

" findProjectRoot returns the project root by searching the src/ folder
" recursively until it's been found till `/`
function! s:findProjectRoot()
    let current_dir = fnameescape(expand('%:p:h'))
    let root_path = finddir("src/", current_dir .";")
    if empty(root_path)
      return ''
    endif

    return fnamemodify(root_path, ':p:h:h')
endfunction


" vim:ts=4:sw=4:et

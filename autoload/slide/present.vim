if !exists("g:go_slide_open_browser")
    let g:go_slide_open_browser = 1
endif

if !exists("g:go_slide_start_server")
    let g:go_slide_start_server = 0
endif


function! slide#present#Present(filename)

    if g:go_slide_start_server == 1
        let command = "present &"
        call system(command)

        if v:shell_error
            echo 'A error has occured. Run this command to see what the problem is:'
            echo command
            return
        endif

    endif
    

    let url = "http://127.0.0.1:3999/".a:filename

    " copy to clipboard
    if has('unix') && !has('xterm_clipboard') && !has('clipboard')
        let @" = url
    else
        let @+ = url
    endif

    if g:go_slide_open_browser != 0
        call go#tool#OpenBrowser(url)
    endif

    echo "vim-go: presentation loaded ".url
endfunction

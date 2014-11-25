function! go#coverlay#Coverlay(...)
    let l:tmpname=tempname()

    let command = "go test -coverprofile=".l:tmpname

    let out = go#tool#ExecuteInDir(command)
    if v:shell_error
        call go#tool#ShowErrors(out)
    else
        " clear previous quick fix window
        call setqflist([])

        highlight covered term=bold ctermbg=green guibg=green
        highlight uncover term=bold ctermbg=red guibg=red

        let lines = readfile(l:tmpname,100)
        let openHTML = 'go tool cover -html='.l:tmpname
        let mode = lines[0]
        for line in lines[1:]
            " file:startline.col,endline.col numstmt count
            let mx = '\([^:]\+\):\(\d\+\)\.\(\d\+\),\(\d\+\)\.\(\d\+\)\s\(\d\+\)\s\(\d\+\)'
            let l = matchstr(line, mx)
            let file = substitute(l, mx, '\1', '')
            let startline  = substitute(l, mx, '\2', '')
            let startcol = substitute(l, mx, '\3', '')
            let endline = substitute(l, mx, '\4', '')
            let endcol = substitute(l, mx, '\5', '')
            let numstmt = substitute(l, mx, '\6', '')
            let cnt = substitute(l, mx, '\7', '')

            let curnr = bufnr("%")
            let iscur = 0
            if file[0] == "_"
                if bufnr(file[1:]) != curnr
                    let iscur = 1
                endif
            else
                for path in split($GOPATH, ':')
                    if bufnr(path . '/src/' . file) == curnr
                        let iscur = 1
                    endif
                endfor
            endif
            if !iscur
                continue
            endif

            "TODO: handle cols
            "let pat1 = '\%>' . startline . 'l\%' . startcol . 'c'
            "let pat2 = '\%<' . endline . 'l\%' . endcol . 'c'
            let pat1 = '\%>' . startline . 'l'
            let pat2 = '\%<' . endline . 'l'
            let pat3 = '\|\%' . startline . 'l\_^\s\+\|\%' . endline . 'l\_^\s\+'
            let color = 'covered'
            if cnt == 0
                let color = 'uncover'
            endif
            silent! call matchadd(color, pat1 . '\_^\s\+' . pat2 . pat3)
        endfor
    endif
    cwindow

    let errors = getqflist()
    if !empty(errors)
        if g:go_jump_to_error
            cc 1 "jump to first error if there is any
        endif
    endif

    call delete(l:tmpname)
endfunction

function! go#coverlay#Clearlay(...)
    "TODO: clear locally
    call clearmatches()
endfunction

" vim:ts=4:sw=4:et

if !exists("g:go_gopath")
    let g:go_gopath = $GOPATH
endif

function! go#coverlay#isopenedon(file, bufnr)
    if a:file[0] == "_"
        if bufnr(a:file[1:]) == a:bufnr
            return 1
        endif
        return 0
    endif
    for path in split(g:go_gopath, ':')
        if bufnr(path . '/src/' . a:file) == a:bufnr
            return 1
        endif
    endfor
    return 0
endfunction

function! go#coverlay#parsegocoverline(line)
    " file:startline.col,endline.col numstmt count
    let mx = '\([^:]\+\):\(\d\+\)\.\(\d\+\),\(\d\+\)\.\(\d\+\)\s\(\d\+\)\s\(\d\+\)'
    let l = matchstr(a:line, mx)
    let ret = {}
    let ret.file = substitute(l, mx, '\1', '')
    let ret.startline  = substitute(l, mx, '\2', '')
    let ret.startcol = substitute(l, mx, '\3', '')
    let ret.endline = substitute(l, mx, '\4', '')
    let ret.endcol = substitute(l, mx, '\5', '')
    let ret.numstmt = substitute(l, mx, '\6', '')
    let ret.cnt = substitute(l, mx, '\7', '')
    return ret
endfunction

function! go#coverlay#genmatch(cov)
    let pat1 = '\%>' . a:cov.startline . 'l'
    let pat2 = '\%<' . a:cov.endline . 'l'
    let pat3 = '\|\%' . a:cov.startline . 'l\_^\s\+\|\%' . a:cov.endline . 'l\_^\s\+\(\}$\)\@!'
    let color = 'covered'
    let prio = 6
    if a:cov.cnt == 0
        let color = 'uncover'
        let prio = 5
    endif
    return {'group': color, 'pattern': pat1 . '\_^\s\+' . pat2 . pat3, 'priority': prio}
endfunction

function! go#coverlay#overlay(file)
    if !exists("b:go_coverlay_matches")
        let b:go_coverlay_matches = []
    endif

    highlight covered term=bold ctermbg=green guibg=green
    highlight uncover term=bold ctermbg=red guibg=red

    let lines = readfile(a:file)
    let mode = lines[0]
    for line in lines[1:]
        let c = go#coverlay#parsegocoverline(line)
        if !go#coverlay#isopenedon(c.file, bufnr("%"))
            continue
        endif
        let m = go#coverlay#genmatch(c)
        let id = matchadd(m.group, m.pattern, m.priority)
        call add(b:go_coverlay_matches, id)
   endfor
endfunction

function! go#coverlay#Coverlay(...)
    let l:tmpname=tempname()

    let command = "go test -coverprofile=".l:tmpname

    let out = go#tool#ExecuteInDir(command)
    if v:shell_error
        call go#tool#ShowErrors(out)
    else
        " clear previous quick fix window
        call setqflist([])
        call go#coverlay#overlay(l:tmpname)
    endif

    let errors = getqflist()
    if !empty(errors)
        cwindow
        if g:go_jump_to_error
            cc 1 "jump to first error if there is any
        endif
    endif

    call delete(l:tmpname)
endfunction

function! go#coverlay#Clearlay(...)
    if !exists("b:go_coverlay_matches")
        return
    endif
    for id in b:go_coverlay_matches
        call matchdelete(id)
    endfor
    let b:go_coverlay_matches = []
endfunction

function! go#coverlay#matches()
    return b:go_coverlay_matches
endfunction

" vim:ts=4:sw=4:et

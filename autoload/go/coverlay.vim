if !exists("g:go_gopath")
    let g:go_gopath = $GOPATH
endif

augroup plugin-go-coverlay
    autocmd!
    autocmd BufEnter,BufWinEnter,BufFilePost * call go#coverlay#draw()
    autocmd BufWinLeave * call go#coverlay#clear()
augroup END

function! go#coverlay#draw()
    call go#coverlay#hook()
    call go#coverlay#clear()
    for m in b:go_coverlay_matches
        let id = matchadd(m.group, m.pattern, m.priority)
        call add(b:go_coverlay_match_ids, id)
    endfor
endfunction

function! go#coverlay#hook()
    "TODO: can we initialize buf local vars more smartly?
    if !exists("b:go_coverlay_matches")
        let b:go_coverlay_matches = []
    endif
    if !exists("b:go_coverlay_match_ids")
        let b:go_coverlay_match_ids = []
    endif
endfunction

"findbufnr look for the number of buffer that opens `file`,
" as it is displayed by the ":ls" command.
"If the buffer doesn't exist, -1 is returned.
function! go#coverlay#findbufnr(file)
    if a:file[0] == "_"
        return bufnr(a:file[1:])
    endif
    for path in split(g:go_gopath, ':')
        let nr = bufnr(path . '/src/' . a:file)
        if nr != -1
            return nr
        endif
    endfor
    return -1
endfunction

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
    call go#coverlay#hook()

    highlight covered term=bold ctermbg=green guibg=green
    highlight uncover term=bold ctermbg=red guibg=red

    if !filereadable(a:file)
        return
    endif
    let lines = readfile(a:file)
    let mode = lines[0]
    for line in lines[1:]
        let c = go#coverlay#parsegocoverline(line)
        let nr = go#coverlay#findbufnr(c.file)
        if nr == -1
            "should we records cov data
            " even if it is not opened currently?
            continue
        endif
        let m = go#coverlay#genmatch(c)
        let matches = get(getbufvar(nr, ""), "go_coverlay_matches", [])
        call add(matches, m)
        call setbufvar(nr, "go_coverlay_matches", matches)
    endfor
    "TODO: can we draw other window for split windows mode?
    call go#coverlay#draw()
endfunction

let s:coverlay_handler_id = ''
let s:coverlay_handler_jobs = {}

function! s:coverlay_handler(job, exit_status, data)
    if !has_key(s:coverlay_handler_jobs, a:job.id)
        return
    endif
    let l:tmpname = s:coverlay_handler_jobs[a:job.id]
    if a:exit_status == 0
        call go#coverlay#overlay(l:tmpname)
    endif

    call delete(l:tmpname)
    unlet s:coverlay_handler_jobs[a:job.id]
endfunction

function! go#coverlay#Coverlay(bang, ...)
    call go#coverlay#Clearlay()
    let l:tmpname=tempname()
    let args = [a:bang, 0, "-coverprofile", l:tmpname]

    if a:0
        call extend(args, a:000)
    endif
    "TODO: add -coverpkg options based on current buf list
    let id = call('go#cmd#Test', args)
    if has('nvim')
        if s:coverlay_handler_id == ''
            let s:coverlay_handler_id = go#jobcontrol#AddHandler(function('s:coverlay_handler'))
        endif
        let s:coverlay_handler_jobs[id] = l:tmpname
        return
    endif
    if !v:shell_error
        call go#coverlay#overlay(l:tmpname)
    endif
    call delete(l:tmpname)
endfunction

function! go#coverlay#Clearlay()
    call go#coverlay#hook()
    call go#coverlay#clear()
    let b:go_coverlay_matches = []
endfunction

function! go#coverlay#clear(...)
    for id in b:go_coverlay_match_ids
        call matchdelete(id)
    endfor
    let b:go_coverlay_match_ids = []
endfunction

function! go#coverlay#matches()
    call go#coverlay#hook()
    return b:go_coverlay_matches
endfunction

" vim:ts=4:sw=4:et

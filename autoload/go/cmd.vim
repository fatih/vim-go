if !exists("g:go_jump_to_error")
    let g:go_jump_to_error = 1
endif

if !exists("g:go_dispatch_enabled")
    let g:go_dispatch_enabled = 0
endif

function! go#cmd#Run(bang, ...)
    let goFiles = '"' . join(go#tool#Files(), '" "') . '"'

    if IsWin()
        exec '!go run ' . goFiles
        if v:shell_error
            redraws! | echon "vim-go: [run] " | echohl ErrorMsg | echon "FAILED"| echohl None
        else
            redraws! | echon "vim-go: [run] " | echohl Function | echon "SUCCESS"| echohl None
        endif

        return
    endif

    let default_makeprg = &makeprg
    if !len(a:000)
        let &makeprg = 'go run ' . goFiles
    else
        let &makeprg = "go run " . expand(a:1)
    endif

    if g:go_dispatch_enabled && exists(':Make') == 2
        silent! exe 'Make!'
    else
        exe 'make!'
    endif
    if !a:bang
        cwindow
        let errors = getqflist()
        if !empty(errors)
            if g:go_jump_to_error
                cc 1 "jump to first error if there is any
            endif
        endif
    endif

    let &makeprg = default_makeprg
endfunction

function! go#cmd#Install(...)
    let pkgs = join(a:000, '" "')
    let command = 'go install "' . pkgs . '"'
    let out = go#tool#ExecuteInDir(command)
    if v:shell_error
        call go#tool#ShowErrors(out)
        cwindow
        let errors = getqflist()
        if !empty(errors)
            if g:go_jump_to_error
                cc 1 "jump to first error if there is any
            endif
        endif
        return
    endif

    if exists("$GOBIN")
        echon "vim-go: " | echohl Function | echon "installed to ". $GOBIN | echohl None
    else
        echon "vim-go: " | echohl Function | echon "installed to ". $GOPATH . "/bin" | echohl None
    endif
endfunction

function! go#cmd#Build(bang, ...)
    let default_makeprg = &makeprg
    let gofiles = join(go#tool#Files(), '" "')
    if v:shell_error
        let &makeprg = "go build . errors"
    else
        let &makeprg = "go build -o /dev/null " . join(a:000, ' ') . ' "' . gofiles . '"'
    endif

    echon "vim-go: " | echohl Identifier | echon "building ..."| echohl None
    if g:go_dispatch_enabled && exists(':Make') == 2
        silent! exe 'Make'
    else
        silent! exe 'make!'
    endif
    redraw!
    if !a:bang
        cwindow
        let errors = getqflist()
        if !empty(errors)
            if g:go_jump_to_error
                cc 1 "jump to first error if there is any
            endif
        else
            redraws! | echon "vim-go: " | echohl Function | echon "[build] SUCCESS"| echohl None
        endif
    endif

    let &makeprg = default_makeprg
endfunction

function! go#cmd#Test(compile, ...)
    let command = "go test "

    " don't run the test, only compile it. Useful to capture and fix errors or
    " to create a test binary.
    if a:compile
        let command .= "-c"
    endif

    if len(a:000)
        let command .= expand(a:1)
    endif

    if len(a:000) == 2
        let command .= a:2
    endif

    if a:compile
        echon "vim-go: " | echohl Identifier | echon "compiling tests ..." | echohl None
    else
        echon "vim-go: " | echohl Identifier | echon "testing ..." | echohl None
    endif

    redraw
    let out = go#tool#ExecuteInDir(command)
    if v:shell_error
        call go#tool#ShowErrors(out)
        cwindow
        let errors = getqflist()
        if !empty(errors)
            if g:go_jump_to_error
                cc 1 "jump to first error if there is any
            endif
        endif
        echon "vim-go: " | echohl ErrorMsg | echon "[test] FAIL" | echohl None
    else
        call setqflist([])
        cwindow

        if a:compile
            echon "vim-go: " | echohl Function | echon "[test] SUCCESS" | echohl None
        else
            echon "vim-go: " | echohl Function | echon "[test] PASS" | echohl None
        endif
    endif
endfunction

function! go#cmd#TestFunc(...)
    " search flags legend (used only)
    " 'b' search backward instead of forward
    " 'c' accept a match at the cursor position
    " 'n' do Not move the cursor
    " 'W' don't wrap around the end of the file
    "
    " for the full list
    " :help search
    let test = search("func Test", "bcnW")

    if test == 0
        echo "vim-go: [test] no test found immediate to cursor"
        return
    end

    let line = getline(test)
    let name = split(split(line, " ")[1], "(")[0]
    let flag = "-run \"" . name . "$\""

    let a1 = ""
    if len(a:000)
        let a1 = a:1

        " add extra space
        let flag = " " . flag
    endif

    call go#cmd#Test(0, a1, flag)
endfunction

function! go#cmd#Coverage(...)
    let l:tmpname=tempname()

    let command = "go test -coverprofile=".l:tmpname

    let out = go#tool#ExecuteInDir(command)
    if v:shell_error
        call go#tool#ShowErrors(out)
    else
        " clear previous quick fix window
        call setqflist([])

        let openHTML = 'go tool cover -html='.l:tmpname
        call go#tool#ExecuteInDir(openHTML)
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

function! go#cmd#Vet()
    echon "vim-go: " | echohl Identifier | echon "calling vet..." | echohl None
    let out = go#tool#ExecuteInDir('go vet')
    if v:shell_error
        call go#tool#ShowErrors(out)
    else
        call setqflist([])
    endif
    cwindow

    let errors = getqflist()
    if !empty(errors)
        if g:go_jump_to_error
            cc 1 "jump to first error if there is any
        endif
    else
        redraw | echon "vim-go: " | echohl Function | echon "[vet] PASS" | echohl None
    endif
endfunction

" vim:ts=4:sw=4:et
"

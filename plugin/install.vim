" install necessary Go tools
if exists("g:go_loaded_install")
    finish
endif
let g:go_loaded_install = 1

if !exists("g:go_bin_path")
    let g:go_bin_path = expand("$HOME/.vim-go/")
else
    " add trailing slash if there is no one
    if g:go_bin_path[-1:-1] != '/' | let g:go_bin_path .= '/' | endif
endif

let s:packages = [
            \ "github.com/nsf/gocode", 
            \ "code.google.com/p/go.tools/cmd/goimports", 
            \ "code.google.com/p/rog-go/exp/cmd/godef", 
            \ "code.google.com/p/go.tools/cmd/oracle", 
            \ "github.com/golang/lint/golint", 
            \ "github.com/kisielk/errcheck",
            \ ]

function! s:CheckAndSetBinaryPaths() 
    for pkg in s:packages
        let basename = fnamemodify(pkg, ":t")
        let binname = "go_" . basename . "_bin"

        if !exists("g:{binname}")
            let g:{binname} = g:go_bin_path . basename
        endif
    endfor
endfunction

call s:CheckAndSetBinaryPaths()

function! s:CheckBinaries()
    if !executable('go')
        echohl Error | echomsg "vim-go: go executable not found." | echohl None
        return -1
    endif

    if !executable('git')
        echohl Error | echomsg "vim-go: git executable not found." | echohl None
        return -1
    endif

    if !executable('hg')
        echohl Error | echomsg "vim.go: hg (mercurial) executable not found." | echohl None
        return -1
    endif
endfunction

function! s:GoInstallBinaries(updateBin) 
    if $GOPATH == ""
        echohl Error 
        echomsg "vim.go: $GOPATH is not set"
        echohl None
        return
    endif

    let err = s:CheckBinaries()
    if err != 0
        return
    endif

    let s:go_bin_old_path = $GOBIN
    let $GOBIN = g:go_bin_path

    for pkg in s:packages
        let basename = fnamemodify(pkg, ":t")
        let binname = "go_" . basename . "_bin"

        if !executable(g:{binname}) || a:updateBin == 1
            echo "Installing ".pkg
            let out = system("go get -u -v ".shellescape(pkg))
            if v:shell_error
                echo "Error installing ". pkg . ": " . out
            endif
        endif
    endfor

    let $GOBIN = s:go_bin_old_path 
endfunction

" try to install at startup
if !exists("g:go_disable_autoinstall")
    call s:GoInstallBinaries(-1)
endif

command! GoUpdateBinaries call s:GoInstallBinaries(1)

" vim:ts=4:sw=4:et

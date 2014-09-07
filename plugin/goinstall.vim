" install necessary Go tools
if exists("g:go_loaded_install")
    finish
endif
let g:go_loaded_install = 1

" these packages are used by vim-go and can be automatically installed if
" needed by the user with GoInstallBinaries
let s:packages = [
            \ "github.com/nsf/gocode", 
            \ "code.google.com/p/go.tools/cmd/goimports", 
            \ "code.google.com/p/rog-go/exp/cmd/godef", 
            \ "code.google.com/p/go.tools/cmd/oracle", 
            \ "github.com/golang/lint/golint", 
            \ "github.com/kisielk/errcheck",
            \ "github.com/jstemmer/gotags",
            \ ]

" CheckAndSetBinaryPaths is used to check whether the given binary in the
" packages list is set as global variable such as g:go_godef_bin. Vim-go uses
" this global variable in system calls.
function! s:CheckAndSetBinaryPaths() 
    if $GOPATH == ""
        echohl Error 
        echomsg "vim.go: $GOPATH is not set"
        echohl None
        return
    endif

    if $GOBIN == ""
        let go_bin_path = $GOPATH . '/bin/'
    else
        let go_bin_path = $GOBIN
    endif

    " add trailing slash if there is no one
    if go_bin_path[-1:-1] != '/' | let go_bin_path .= '/' | endif

    for pkg in s:packages
        let basename = fnamemodify(pkg, ":t")
        let binname = "go_" . basename . "_bin"

        if !exists("g:{binname}")
            let g:{binname} = go_bin_path . basename
        endif
    endfor
endfunction


" CheckBinarires checks if the necessary binaries to install the Go tool
" commands are available.
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

" GoInstallBinaries downloads and install all necessary binaries stated in the
" packages variable. It uses by default $GOBIN or $GOPATH/bin as the binary
" target install directory. GoInstallBinaries doesn't install binaries if they
" exist, to update current binaries pass 1 to the argument.
function! s:GoInstallBinaries(updateBinaries) 
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

    if $GOBIN == ""
        let go_bin_path = $GOPATH . '/bin/'
        let $GOBIN = go_bin_path

        echohl WarningMsg
        echomsg "vim.go: $GOBIN is not set. Using: ". go_bin_path
        echohl None
    else
        let go_bin_path = $GOBIN
    endif


    for pkg in s:packages
        let basename = fnamemodify(pkg, ":t")
        let binname = "go_" . basename . "_bin"

        if !executable(g:{binname}) || a:updateBinaries == 1
            if a:updateBinaries == 1 
                echo "vim-go: Updating ". basename .". Reinstalling ". pkg . " to folder " . go_bin_path
            else
                echo "vim-go: ". basename ." not found. Installing ". pkg . " to folder " . go_bin_path
            endif

            let out = system("go get -u -v ".shellescape(pkg))
            if v:shell_error
                echo "Error installing ". pkg . ": " . out
            endif
        endif
    endfor
endfunction

call s:CheckAndSetBinaryPaths()

command! GoInstallBinaries call s:GoInstallBinaries(-1)
command! GoUpdateBinaries call s:GoInstallBinaries(1)

" vim:ts=4:sw=4:et

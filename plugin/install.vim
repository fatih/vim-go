" install necessary Go tools
if exists("g:go_loaded_install")
  finish
endif
let g:go_loaded_install = 1

if !exists("g:go_bin_path")
    let g:go_bin_path = expand("$HOME/.vim-go/")
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
  let out = system("which go")
  if v:shell_error != 0
    echohl Error | echomsg "vim-go: go executable not found." | echohl None
		return -1
	endif

  let out = system("which git")
  if v:shell_error != 0
    echohl Error | echomsg "vim-go: git executable not found." | echohl None
		return -1
	endif

  let out = system("which hg")
  if v:shell_error != 0
    echohl Error | echomsg "vim.go: hg (mercurial) executable not found." | echohl None
		return -1
	endif
endfunction

function! s:GoInstallBinaries(updateBin) 
	if exists("g:go_disable_autoinstall")
		if a:updateBin == 1
			echom "vim.go: auto install is disabled. Enable it with 'let g:go_disable_autoinstall = 0'"
		endif

		return
	endif

	if $GOPATH == ""
		echohl Error 
		echomsg "vim.go: $GOPATH is not set"
		echomsg "vim.go: you can disable auto install with 'let g:go_disable_autoinstall = 1'"
		echohl None
		return
	endif


	let err = s:CheckBinaries()
	if err != 0
		echohl Error | echomsg "vim.go: you can disable auto install with 'let g:go_disable_autoinstall = 1'" | echohl None
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

" try to install once
call s:GoInstallBinaries(-1)

command! GoUpdateBinaries call s:GoInstallBinaries(1)

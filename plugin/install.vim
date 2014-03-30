" install necessary Go tools
if exists("g:go_loaded_install")
  finish
endif
let g:go_loaded_install = 1


if !exists("g:go_bin_path")
    let g:go_bin_path = expand("$HOME/.vim-go/")
endif

let $GOBIN = g:go_bin_path

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


function! s:InstallGoBinaries(updateBin) 
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
endfunction


call s:CheckAndSetBinaryPaths()

if !exists("g:go_disable_autoinstall")
  let out = system("which go")
  if v:shell_error != 0
    echohl Error | echomsg "Go executable not found." | echohl None
  else
    call s:InstallGoBinaries(-1)
  endif
endif

command! GoUpdateBinaries call s:InstallGoBinaries(1)


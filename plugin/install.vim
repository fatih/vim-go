" install necessary Go tools
if exists("g:loaded_install")
  finish
endif
let g:loaded_install = 1

let g:bin_path = expand("$HOME/.vim-go/")
let $GOBIN = g:bin_path

let packages = ["github.com/nsf/gocode", "code.google.com/p/go.tools/cmd/goimports", "code.google.com/p/go.tools/cmd/goimports", "code.google.com/p/rog-go/exp/cmd/godef", "code.google.com/p/go.tools/cmd/oracle", "github.com/golang/lint/golint"]

for pkg in packages
    let basename = fnamemodify(pkg, ":t")
    let binname = basename . "_bin"

    if !exists("g:{binname}")
        let g:{binname} = g:bin_path . basename
    endif

    if !executable(g:{binname})
        execute "!go get -u -v ".shellescape(pkg)
    endif

endfor


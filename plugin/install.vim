" install necessary Go tools
if exists("g:go_loaded_install")
  finish
endif
let g:go_loaded_install = 1

if !exists("g:go_bin_path")
    let g:go_bin_path = expand("$HOME/.vim-go/")
endif

let $GOBIN = g:go_bin_path

let packages = ["github.com/nsf/gocode", "code.google.com/p/go.tools/cmd/goimports", "code.google.com/p/go.tools/cmd/goimports", "code.google.com/p/rog-go/exp/cmd/godef", "code.google.com/p/go.tools/cmd/oracle", "github.com/golang/lint/golint"]

" Install and set global binary paths
for pkg in packages
    let basename = fnamemodify(pkg, ":t")
    let binname = "go_" . basename . "_bin"

    if !exists("g:{binname}")
        let g:{binname} = g:go_bin_path . basename
    endif

    if !executable(g:{binname})
        execute "!go get -u -v ".shellescape(pkg)
    endif

endfor


" install necessary Go tools
if exists("g:loaded_install")
  finish
endif
let g:loaded_install = 1

let g:bin_path = expand("$HOME/.vim-go/")
let $GOBIN = g:bin_path


" install gocode if not available
if !exists("g:gocode_bin")
    let g:gocode_bin = g:bin_path . "gocode"
endif

if !filereadable(g:gocode_bin)
  let import_path = "github.com/nsf/gocode"
  execute "!go get -u -v ".shellescape(import_path)
endif

" install goimports if not available
if !exists("g:goimports_bin")
    let g:goimports_bin =  g:bin_path . "goimports"
endif

if !filereadable(g:goimports_bin)
  let import_path = "code.google.com/p/go.tools/cmd/goimports"
  execute "!go get -u -v ".shellescape(import_path)
endif


" install godef if not available
if !exists("g:godef_bin")
    let g:godef_bin = g:bin_path . "godef"
endif

if !filereadable(g:godef_bin)
  let import_path = "code.google.com/p/rog-go/exp/cmd/godef"
  execute "!go get -u -v ".shellescape(import_path)
endif

" install oracle if not available
if !exists("g:oracle_bin")
    let g:oracle_bin = g:bin_path . "oracle"
endif

if !filereadable(g:oracle_bin)
  let import_path = "code.google.com/p/go.tools/cmd/oracle"
  execute "!go get -u -v ".shellescape(import_path)
endif

" install golint if not available
if !exists("g:golint_bin")
    let g:golint_bin = g:bin_path . "golint"
endif

if !filereadable(g:golint_bin)
  let import_path = "github.com/golang/lint/golint"
  execute "!go get -u -v ".shellescape(import_path)
endif


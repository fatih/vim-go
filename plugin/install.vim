" install necessary Go tools
if exists("g:loaded_install")
  finish
endif
let g:loaded_install = 1

" install gocode if not available
if !exists("g:gocode_bin")
    let g:gocode_bin = expand("$HOME/.vim/bundle/go.vim/binary/gocode/gocode")
endif

if !filereadable(g:gocode_bin)
  let import_path = "github.com/nsf/gocode"
  let $GOBIN = expand("$HOME/.vim/bundle/go.vim/binary/gocode/")
  echom "Installing gocode ..."
  execute "!go get -u -v ".shellescape(import_path)
endif

" install goimports if not available
if !exists("g:goimports_bin")
    let g:goimports_bin = expand("$HOME/.vim/bundle/go.vim/binary/goimports/goimports")
endif

if !filereadable(g:goimports_bin)
  let import_path = "code.google.com/p/go.tools/cmd/goimports"
  let $GOBIN = expand("$HOME/.vim/bundle/go.vim/binary/goimports/")
  echom "Installing goimports ..."
  execute "!go get -u -v ".shellescape(import_path)
endif


" install goimports if not available
if !exists("g:godef_bin")
    let g:godef_bin = expand("$HOME/.vim/bundle/go.vim/binary/godef/godef")
endif

if !filereadable(g:godef_bin)
  let import_path = "code.google.com/p/rog-go/exp/cmd/godef"
  let $GOBIN = expand("$HOME/.vim/bundle/go.vim/binary/godef/")
  echom "Installing godef ..."
  execute "!go get -u -v ".shellescape(import_path)
endif

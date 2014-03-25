" install necessary Go tools
if exists("g:loaded_install")
  finish
endif
let g:loaded_install = 1

if !exists("g:gocode_bin")
    let g:gocode_bin = expand("$HOME/.vim/bundle/go.vim/binary/gocode/gocode")
endif

" install gocode if not available
if !filereadable(g:gocode_bin)
  let import_path = "github.com/nsf/gocode"
  let $GOBIN = expand("$HOME/.vim/bundle/go.vim/binary/gocode/")
  echom "Installing gocode ..."
  execute "silent !go get -u ".shellescape(import_path)
endif

if !exists("g:goimports_bin")
    let g:goimports_bin = expand("$HOME/.vim/bundle/go.vim/binary/goimports/goimports")
endif

" install goimports if not available
if !filereadable(g:goimports_bin)
  let import_path = "code.google.com/p/go.tools/cmd/goimports"
  let $GOBIN = expand("$HOME/.vim/bundle/go.vim/binary/goimports/")
  echom "Installing goimports ..."
  execute "silent !go get -u ".shellescape(import_path)
endif

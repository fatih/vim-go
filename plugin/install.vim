" check for ctags folder, if not exist extract our ctags binary
"
"
if exists("g:loaded_install")
  finish
endif
let g:loaded_install = 1

if !exists("g:gocode_bin")
    let g:gocode_bin = expand("$HOME/.vim/bundle/go.vim/binary/gocode/gocode")
endif

" install gocode
if !filereadable(g:gocode_bin)
  let import_path = "github.com/nsf/gocode"
  let $GOBIN = expand("$HOME/.vim/bundle/go.vim/binary/gocode/")
  "silent !clear
  echom "Installing gocode..."
  execute "silent !go get -u ".shellescape(import_path)
endif

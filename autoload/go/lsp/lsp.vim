" don't spam the user when Vim is started in Vi compatibility mode
let s:cpo_save = &cpo
set cpo&vim

" go#lsp#lsp#Position returns the LSP text position. If no arguments are
" provided, the cursor position is assumed. Otherwise, there should be two
" arguments: the line and the column.
function! go#lsp#lsp#Position(...)
  if a:0 < 2
    let [l:line, l:col] = getpos('.')[1:2]
  else
    let l:line = a:1
    let l:col = a:2
  endif
	let l:content = getline(l:line)

  " LSP uses 0-based lines.
  let l:line -= 1

  let l:offset = l:col - 1

  let l:cmd = [go#path#CheckBinPath('lsp-position'), '-offset', l:offset]
  let [l:out, l:exit]= go#util#Exec(l:cmd, l:content)

  if l:exit != 0
    call go#util#EchoWarn(l:out)
    " assume that the line and column calculated directly from the cursor
    " position is correct, because in the vast majority of cases the column
    " will be the number of utf-16 code units to the column, too.
    " than one utf-16 code unit
    return [l:line, l:col]
  endif

  let l:col = str2nr(split(l:out)[0])

  return [l:line, l:col]
endfunction

" restore Vi compatibility settings
let &cpo = s:cpo_save
unlet s:cpo_save

" vim: sw=2 ts=2 et

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
  return [l:line - 1, s:character(l:line, l:col)]
endfunction

function! s:strlen(str) abort
  let l:runes = split(a:str, '\zs')
  return len(l:runes) + len(filter(l:runes, 'char2nr(v:val)>=0x10000'))
endfunction

function! s:character(line, col) abort
  return s:strlen(getline(a:line)[:col([a:line, a:col - 1])])
endfunction

" restore Vi compatibility settings
let &cpo = s:cpo_save
unlet s:cpo_save

" vim: sw=2 ts=2 et

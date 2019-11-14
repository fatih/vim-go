let s:cpo_save = &cpo
set cpo&vim

function! go#inter#InterFunc(...) abort
  let pos = getpos('.')
  let [result, err] = go#util#Exec(['interfunc', "-dir", fnameescape(expand('%:p:h')), a:1])
  if err
    call go#util#EchoError(result)
    return
  endif
  silent put =result
  call setpos('.', pos)
endfunction

" restore Vi compatibility settings
let &cpo = s:cpo_save
unlet s:cpo_save

" vim: sw=2 ts=2 et

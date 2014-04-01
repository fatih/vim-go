if exists("g:go_loaded_errcheck") 
  finish
endif
let g:go_loaded_errcheck = 1

command! GoErrCheck call s:ErrCheck()

function! s:ErrCheck() abort
  let out = system(g:go_errcheck_bin . ' ' . shellescape(expand('%:p:h')))
  if v:shell_error
		call g:GoCatchErrors(out, "GoErrCheck")
  else
    call setqflist([])
  endif
  cwindow
endfunction


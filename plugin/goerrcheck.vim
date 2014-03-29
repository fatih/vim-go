if exists("b:go_loaded_errcheck") 
  finish
endif
let b:go_loaded_errcheck = 1

command! -buffer GoErrCheck call s:ErrCheck()

function! s:ErrCheck() abort
  let mx = '\S\+:\d\+:\d\+:[^:]\+:[^:]\+$'
  let lines = system(g:go_errcheck_bin . ' ' . shellescape(expand('%:p:h')))
  let splitted = split(lines, "\n") 
  map(splitted, 'matchstr(v:val, mx)')
  cexpr splitted
  cwindow
endfunction


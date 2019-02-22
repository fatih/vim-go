" don't spam the user when Vim is started in Vi compatibility mode
let s:cpo_save = &cpo
set cpo&vim

" Test alternates between the implementation of code and the test code.
function! go#alternate#Switch(bang, cmd) abort
  let file = expand('%')
  if empty(file)
    call go#util#EchoError("no buffer name")
    return
  elseif file =~# '^\f\+_internal_test\.go$'
    let l:root = split(file, '_internal_test.go$')[0]
    let l:alt_files = [l:root . ".go", l:root . '_test.go']
  elseif file =~# '^\f\+_test\.go$'
    let l:root = split(file, '_test.go$')[0]
    let l:alt_files = [l:root . "_internal_test.go", l:root . '.go']
  elseif file =~# '^\f\+\.go$'
    let l:root = split(file, ".go$")[0]
    let l:alt_files = [l:root . '_test.go', l:root . '_internal_test.go']
  else
    call go#util#EchoError("not a go file")
    return
  endif
  let l:alt_file = ""
  for alt_file in l:alt_files
    if !filereadable(alt_file) && !bufexists(alt_file) && !a:bang
      continue
    elseif empty(a:cmd)
      execute ":" . go#config#AlternateMode() . " " . alt_file
      return
    else
      execute ":" . a:cmd . " " . alt_file
      return
    endif
  endfor
  call go#util#EchoError("couldn't find " . join(l:alt_files, " or "))
endfunction

" restore Vi compatibility settings
let &cpo = s:cpo_save
unlet s:cpo_save

" vim: sw=2 ts=2 et

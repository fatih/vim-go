" Alternate between the implementation of code and the test code.
"
" if a:bang is true then we will switch to the new file even if it doesn't
" exist.
" a:cmd is the edit command, such as :edit, :tabedit, :vsplit, etc.
function! go#alternate#Switch(bang, cmd)
  let l:file = expand('%')
  if empty(l:file)
    call go#util#EchoError('no buffer name')
    return
  elseif l:file[-8:] is# '_test.go'
    let l:alt_file = l:file[:-9] . '.go'
  elseif l:file[-3:] is# '.go'
    let l:alt_file = l:file[:-4] . '_test.go'
  else
    call go#util#EchoError(printf('%s is not a go file', l:file))
    return
  endif

  if !filereadable(l:alt_file) && !bufexists(l:alt_file) && !a:bang
    call go#util#EchoError("couldn't find " . l:alt_file)
    return
  endif

  let l:cmd = empty(a:cmd) ? go#config#AlternateMode() : a:cmd
  if bufloaded(l:alt_file)
    if l:cmd is# 'edit'
      let l:cmd = 'buffer'
    else
      let l:cmd = 'sbuffer'
    endif
  endif

  exe printf(':%s %s', l:cmd, fnameescape(l:alt_file))
endfunction

" vim: sw=2 ts=2 et

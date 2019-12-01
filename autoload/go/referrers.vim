" don't spam the user when Vim is started in Vi compatibility mode
let s:cpo_save = &cpo
set cpo&vim

function! go#referrers#Referrers(selected) abort
  let l:mode = go#config#ReferrersMode()
  if l:mode == 'guru'
		call go#guru#Referrers(a:selected)
    return
  elseif l:mode == 'gopls'
    if !go#config#GoplsEnabled()
      call go#util#EchoError("go_referrers_mode is 'gopls', but gopls is disabled")
    endif
    let [l:line, l:col] = getpos('.')[1:2]
    let [l:line, l:col] = go#lsp#lsp#Position(l:line, l:col)
    let l:fname = expand('%:p')
    call go#lsp#Referrers(l:fname, l:line, l:col, funcref('s:parse_guru_output'))
    return
  else
    call go#util#EchoWarning('unknown value for g:go_referrers_mode')
  endif
endfunction

" restore Vi compatibility settings
let &cpo = s:cpo_save
unlet s:cpo_save

" vim: sw=2 ts=2 et

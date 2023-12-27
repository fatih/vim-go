" don't spam the user when Vim is started in Vi compatibility mode
let s:cpo_save = &cpo
set cpo&vim

function! go#extract#Extract(line1, line2) abort
  if !go#config#GoplsEnabled()
    call go#util#EchoError('GoExtract requires gopls, but gopls is disabled')
    return
  endif

  call go#lsp#Extract(a:line1, a:line2)
  return
endfunction

" restore Vi compatibility settings
let &cpo = s:cpo_save
unlet s:cpo_save

" vim: sw=2 ts=2 et

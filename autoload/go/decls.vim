if !exists('g:go_decls_mode')
  let g:go_decls_mode = 'ctrlp'
endif

function! go#decls#Decls(mode, ...) abort
  if g:go_decls_mode == 'ctrlp'
    if globpath(&rtp, 'plugin/ctrlp.vim') != ""
      call ctrlp#init(call("ctrlp#decls#cmd", [a:mode] + a:000))
    else
      call go#util#EchoError("ctrlp.vim plugin is not installed. Please install from: https://github.com/ctrlpvim/ctrlp.vim")
    end
  elseif g:go_decls_mode == 'fzf'
    call call("fzf#decls#cmd", [a:mode] + a:000)
  end
endfunction

" vim: sw=2 ts=2 et

function! go#config#AutodetectGopath() abort
	return get(g:, 'go_autodetect_gopath', 0)
endfunction

function! go#config#ListTypeCommands() abort
  return get(g:, 'go_list_type_commands', {})
endfunction

" vim: sw=2 ts=2 et

function! go#config#AutodetectGopath() abort
	return get(g:, 'go_autodetect_gopath', 0)
endfunction

function! go#config#ListTypeCommands() abort
  return get(g:, 'go_list_type_commands', {})
endfunction

function! go#config#VersionWarning() abort
  return get(g:, 'go_version_warning', 1)
endfunction

function! go#config#BuildTags() abort
  return get(g:, 'go_build_tags', '')
endfunction

function! go#config#SetBuildTags(value) abort
  if a:value == ""
    if exists('g:go_build_tags')
      unlet g:go_build_tags
    endif
    return
  endif

  let g:go_build_tags = a:value
endfunction

function! go#config#TestTimeout() abort
 return get(g:, 'go_test_timeout', '10s')
endfunction

function! go#config#TestShowName() abort
  return get(g:, 'go_test_show_name', 0)
endfunction

function! go#config#TermHeight() abort
  return get(g:, 'go_term_height', winheight(0))
endfunction

function! go#config#TermWidth() abort
  return get(g:, 'go_term_width', winwidth(0))
endfunction

function! go#config#TermMode() abort
  return get(g:, 'go_term_mode', 'vsplit')
endfunction

function! go#config#TermEnabled() abort
  return get(g:, 'go_term_enabled', 0)
endfunction

function! go#config#SetTermEnabled(value) abort
  let g:go_term_enabled = a:value
endfunction

" vim: sw=2 ts=2 et

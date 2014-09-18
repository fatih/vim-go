let g:go_loaded_gosnippets = 1

function! s:GoNeosnippet()
	if globpath(&rtp, 'plugin/neosnippet.vim') == ""
		return
	endif

	let g:neosnippet#enable_snipmate_compatibility = 1
	exec 'NeoSnippetSource' globpath(&rtp, 'gosnippets/snippets/go.snip')
endfunction

if g:go_snippet_engine == "neosnippet"
	call s:GoNeosnippet()
endif

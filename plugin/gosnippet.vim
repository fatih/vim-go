if exists("g:go_loaded_gosnippets")
  finish
endif
let g:go_loaded_gosnippets = 1


" by default UltiSnips
if !exists("g:go_snippet_engine")
	let g:go_snippet_engine = "ultisnips"
endif

function! s:GoNeosnippet()
	if globpath(&rtp, 'plugin/neosnippet.vim') == ""
		return
	endif

	imap <expr><TAB> neosnippet#expandable_or_jumpable() ?
	\ "\<Plug>(neosnippet_expand_or_jump)"
	\: pumvisible() ? "\<C-n>" : "\<TAB>"
	smap <expr><TAB> neosnippet#expandable_or_jumpable() ?
	\ "\<Plug>(neosnippet_expand_or_jump)"
	\: "\<TAB>"

	let g:neosnippet#snippets_directory = globpath(&rtp, 'gosnippets/snippets')
	let g:neosnippet#enable_snipmate_compatibility = 1
endfunction

function! s:GoUltiSnips()
	if globpath(&rtp, 'plugin/UltiSnips.vim') == ""
		return
	endif

	function! g:UltiSnips_Complete()
		call UltiSnips#ExpandSnippetOrJump()
		if g:ulti_expand_or_jump_res == 0
			if pumvisible()
				return "\<C-N>"
			else
				return "\<TAB>"
			endif
		endif

		return ""
		endif
	endfunction

	function! g:UltiSnips_Reverse()
		call UltiSnips#JumpBackwards()
		if g:ulti_jump_backwards_res == 0
			return "\<C-P>"
		endif

		return ""
	endfunction

	if !exists("g:UltiSnipsSnippetDirectories")
			let g:UltiSnipsSnippetDirectories = ["gosnippets/UltiSnips"]
	else
			let g:UltiSnipsSnippetDirectories += ["gosnippets/UltiSnips"]
	endif

	if !exists("g:UltiSnipsJumpForwardTrigger")
		 let g:UltiSnipsJumpForwardTrigger = "<tab>"
	endif

	if !exists("g:UltiSnipsJumpBackwardTrigger")
		 let g:UltiSnipsJumpBackwardTrigger="<s-tab>"
	endif

	au BufEnter * exec "inoremap <silent> " . g:UltiSnipsExpandTrigger . " <C-R>=g:UltiSnips_Complete()<cr>"
	au BufEnter * exec "inoremap <silent> " . g:UltiSnipsJumpBackwardTrigger . " <C-R>=g:UltiSnips_Reverse()<cr>"

endfunction


if g:go_snippet_engine == "ultisnips"
	call s:GoUltiSnips()
elseif g:go_snippet_engine == "neosnippet"
	call s:GoNeosnippet()
endif

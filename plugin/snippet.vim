if exists("g:go_loaded_snippets")
  finish
endif
let g:go_loaded_snippets = 1

" If this exists, it means UltiSnips is installed Return if it's not installed
if globpath(&rtp, 'plugin/UltiSnips.vim') == ""
    finish
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

au BufEnter * exec "inoremap <silent> " . g:UltiSnipsExpandTrigger . " <C-R>=g:UltiSnips_Complete()<cr>"
au BufEnter * exec "inoremap <silent> " . g:UltiSnipsJumpBackwardTrigger . " <C-R>=g:UltiSnips_Reverse()<cr>"

let g:UltiSnipsSnippetDirectories=["gosnippets"]

if !exists("g:UltiSnipsJumpForwardTrigger")
   let g:UltiSnipsJumpForwardTrigger = "<tab>"
endif

if !exists("g:UltiSnipsJumpBackwardTrigger")
   let g:UltiSnipsJumpBackwardTrigger="<s-tab>"
endif

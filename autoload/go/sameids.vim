" don't spam the user when Vim is started in Vi compatibility mode
let s:cpo_save = &cpo
set cpo&vim

function! go#sameids#SameIds(showstatus) abort
  if !go#config#GoplsEnabled()
    call go#util#EchoError("GoSameIds requires gopls, but gopls is disabled")
    return
  endif

  " check if the version of Vim being tested supports matchaddpos()
  if !exists("*matchaddpos")
    call go#util#EchoError("GoSameIds requires 'matchaddpos'. Update your Vim/Neovim version.")
    return
  endif

  " check if the version of Vim being tested supports json_decode()
  if !exists("*json_decode")
    call go#util#EchoError("GoSameIds requires 'json_decode'. Update your Vim/Neovim version.")
    return
  endif

  let [l:line, l:col] = getpos('.')[1:2]
  let [l:line, l:col] = go#lsp#lsp#Position(l:line, l:col)
  call go#lsp#SameIDs(0, expand('%:p'), l:line, l:col, funcref('s:same_ids_highlight'))
endfunction

function! s:same_ids_highlight(exit_val, result, mode) abort
  call go#sameids#ClearSameIds() " clear at the start to reduce flicker

  if type(a:result) != type({}) && !go#config#AutoSameids()
    call go#util#EchoError("malformed same id result")
    return
  endif

  if !has_key(a:result, 'sameids') || len(a:result.sameids) == 0
    if !go#config#AutoSameids()
      call go#util#EchoError("no references found for the given identifier")
    endif
    return
  endif

  let same_ids = a:result['sameids']

  " highlight the lines
  let l:matches = []
  for pos in same_ids
    let poslen = pos[2] - pos[1]
    let l:matches = add(l:matches, [pos[0], pos[1], poslen])
  endfor

  call go#util#HighlightPositions('goSameId', l:matches)

  if go#config#AutoSameids()
    " re-apply SameIds at the current cursor position at the time the buffer
    " is redisplayed: e.g. :edit, :GoRename, etc.
    augroup vim-go-sameids
      autocmd! * <buffer>
      if has('textprop')
        autocmd BufReadPost <buffer> nested call go#sameids#SameIds(0)
      else
        autocmd BufWinEnter <buffer> nested call go#sameids#SameIds(0)
      endif
    augroup end
  endif
endfunction

" ClearSameIds returns 0 when it removes goSameId groups and non-zero if no
" goSameId groups are found.
function! go#sameids#ClearSameIds() abort
  let l:cleared = go#util#ClearHighlights('goSameId')

  if !l:cleared
    return 1
  endif

  " remove the autocmds we defined
  augroup vim-go-sameids
    autocmd! * <buffer>
  augroup end

  return 0
endfunction

function! go#sameids#ToggleSameIds() abort
  if go#sameids#ClearSameIds() != 0
    call go#sameids#SameIds(1)
  endif
endfunction

function! go#sameids#AutoToggleSameIds() abort
  if go#config#AutoSameids()
    call go#util#EchoProgress("sameids auto highlighting disabled")
    call go#sameids#ClearSameIds()
    call go#config#SetAutoSameids(0)
  else
    call go#util#EchoSuccess("sameids auto highlighting enabled")
    call go#config#SetAutoSameids(1)
  endif
  call go#auto#update_autocmd()
endfunction

" restore Vi compatibility settings
let &cpo = s:cpo_save
unlet s:cpo_save

" vim: sw=2 ts=2 et

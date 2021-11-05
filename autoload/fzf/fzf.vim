" don't spam the user when Vim is started in Vi compatibility mode
let s:cpo_save = &cpo
set cpo&vim

function! fzf#fzf#sink(str) abort
  if len(a:str) < 2
    return
  endif

  let s:current_dir = expand('%:p:h')
  
  try
    " we jump to the file directory so we can get the fullpath via fnamemodify
    " below
    let l:dir = go#util#Chdir(s:current_dir)

    let vals = matchlist(a:str[1], '|\(.\{-}\):\(\d\+\):\(\d\+\)\s*\(.*\)|')

    " i.e: main.go
    let filename =  vals[1]
    let line =  vals[2]
    let col =  vals[3]

    " i.e: /Users/fatih/vim-go/main.go
    let filepath =  fnamemodify(filename, ":p")

    let cmd = get({'ctrl-x': 'split',
          \ 'ctrl-v': 'vertical split',
          \ 'ctrl-t': 'tabe'}, a:str[0], 'e')
    execute cmd fnameescape(filepath)
    call cursor(line, col)
    silent! norm! zvzz
  finally
    "jump back to old dir
    call go#util#Chdir(l:dir)
  endtry
endfunction

" restore Vi compatibility settings
let &cpo = s:cpo_save
unlet s:cpo_save

" vim: sw=2 ts=2 et

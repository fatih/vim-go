" don't spam the user when Vim is started in Vi compatibility mode
let s:cpo_save = &cpo
set cpo&vim

function! s:source(...) abort
  let ret_files = []

  let l:bin = "gopls"
  let l:fname = expand('%:p')
  let [l:line, l:col] = getpos('.')[1:2]
  let pos = printf("%s:%s:%s",
        \ l:fname,
        \ l:line,
        \ l:col
        \)

  let bin_path = go#path#CheckBinPath(l:bin)
  if empty(bin_path)
    return
  endif

  call go#cmd#autowrite()

  let [l:out, l:err] = go#util#Exec([l:bin, 'implementation', l:pos])
  if l:err
    call go#util#EchoError(l:out)
    return
  endif

  for line in split(out, '\n')
    let vals = matchlist(line, '\(.\{-}\):\(\d\+\):\(\d\+\)-\(\d\+\)')
    let filename = fnamemodify(expand(vals[1]), ":~:.")
    let pos = printf("|%s:%s:%s|",
          \ l:filename,
          \ l:vals[2],
          \ l:vals[3]
          \)
    call add(ret_files, printf("%s:%s\t%s",
          \ l:filename,
          \ l:vals[2],
          \ pos 
          \))
  endfor
  return sort(ret_files)
endfunc


function! fzf#implements#cmd(...) abort
  let l:spec = {
        \ 'source': call('<sid>source', [a:000]),
        \ 'sink*': function('fzf#fzf#sink'),
        \ 'options': printf('-n 1 --with-nth 1 --delimiter=$''\t'' --ansi --prompt "GoImplements> " --expect=ctrl-t,ctrl-v,ctrl-x')
        \ }
  call fzf#run(fzf#wrap("GoImplements", fzf#vim#with_preview(l:spec, 'right:50%:nohidden')))
endfunc


" restore Vi compatibility settings
let &cpo = s:cpo_save
unlet s:cpo_save

" vim: sw=2 ts=2 et

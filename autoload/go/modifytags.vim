if !exists("g:go_gomodifytags_bin")
  let g:go_gomodifytags_bin = "gomodifytags"
endif

function! go#modifytags#Run(bang, line1, line2, tags) abort
  let l:tmpname = tempname()
  call writefile(go#util#GetLines(), l:tmpname)
  if go#util#IsWin()
    let l:tmpname = tr(l:tmpname, '\', '/')
  endif

  let tags = split(a:tags, '\s\+')
  if len(tags) == 0
    let tags = ['json']
  endif

  let cmd = [
  \  g:go_gomodifytags_bin,
  \  '-file='.l:tmpname,
  \  '-line='.a:line1.','.a:line2,
  \  (a:bang ? '-remove-tags=' : '-add-tags=').join(tags, ',')
  \]
  let command = join(cmd, " ")

  " execute our command...
  let out = go#util#System(command)
  if go#util#ShellError() == 0
    call writefile(split(out, "\n"), l:tmpname)
    call go#modifytags#update_file(l:tmpname, expand('%'))
  else
    let out = substitute(substitute(out, '[\r\n]', ' ', 'g'), '\s\+$', '', '')
    echohl Error | echomsg "Gomodifytags: " . out | echohl None
  endif
endfunction

function! go#modifytags#update_file(source, target) 
  " remove undo point caused via BufWritePre
  try | silent undojoin | catch | endtry

  let old_fileformat = &fileformat
  if exists("*getfperm")
    " save file permissions
    let original_fperm = getfperm(a:target)
  endif

  call rename(a:source, a:target)

  " restore file permissions
  if exists("*setfperm") && original_fperm != ''
    call setfperm(a:target , original_fperm)
  endif

  " reload buffer to reflect latest changes
  silent! edit!

  let &fileformat = old_fileformat
  let &syntax = &syntax
endfunction

" vim: sw=2 ts=2 et

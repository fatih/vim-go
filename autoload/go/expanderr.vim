function! go#expanderr#ExpandErr() abort
  let binpath = go#path#CheckBinPath('expanderr')
  if empty(binpath)
    return
  endif

  let l:cmd = [binpath, '-format', 'json',
        \ bufname('') . ':#' . go#util#OffsetCursor()]

  let l:out = go#util#System(go#util#Shelljoin(l:cmd))
  if go#util#ShellError() != 0
    call go#util#EchoError(l:out)
    return
  endif

  try
    let l:json = json_decode(l:out)
  catch
    call go#util#EchoError(l:out)
    return
  endtry

  let l:code = l:json['lines']
  let l:pos = getpos('.')

  try
    call setline('.', l:code[0])
    call append('.', l:code[1:])
  finally
    call setpos('.', l:pos)
  endtry
endfunction

" vim: sw=2 ts=2 et

function! go#fillstruct#FillStruct() abort
  let binpath = go#path#CheckBinPath('fillstruct')
  if empty(binpath)
    return
  endif

  let l:cmd = [binpath,
      \ '-file', bufname(''),
      \ '-offset', go#util#OffsetCursor()]

  " Read from stdin if modified.
  if &modified
    call add(l:cmd, '-modified')
    let l:out = go#util#System(go#util#Shelljoin(l:cmd), go#util#archive())
  else
    let l:out = go#util#System(go#util#Shelljoin(l:cmd))
  endif

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

  let l:code = split(l:json['code'], "\n")
  let l:pos = getpos('.')

  try
    " Add any code before/after the struct.
    exe l:json['start'] . 'go'
    let l:code[0] = getline('.')[:col('.')-1] . l:code[0]
    exe l:json['end'] . 'go'
    let l:code[len(l:code)-1] .= getline('.')[col('.'):]

    " Indent every line except the first one; makes it look nice.
    let l:indent = repeat("\t", indent('.') / &ts)
    for i in range(1, len(l:code)-1)
      let l:code[l:i] = l:indent . l:code[i]
    endfor

    " Out with the old ...
    exe 'normal! ' . l:json['start'] . 'gov' . l:json['end'] . 'gox'
    " ... in with the new.
    call setline('.', l:code[0])
    call append('.', l:code[1:])
  finally
    call setpos('.', l:pos)
  endtry
endfunction

" vim: sw=2 ts=2 et

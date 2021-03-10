" don't spam the user when Vim is started in Vi compatibility mode
let s:cpo_save = &cpo
set cpo&vim

function! go#cyclo#Cyclo() abort
  let l:cmd = ['gocyclo', bufname('')]

  " Read from stdin if modified.
  if &modified
    let [l:out, l:err] = go#util#Exec(l:cmd, go#util#archive())
  else
    let [l:out, l:err] = go#util#Exec(l:cmd)
  endif

  if l:err
    call go#util#EchoError(l:out)
    return
  endif
  " maybe errformat=",%m\ %f:%l:%c" would be clearer
  let errformat = ",%n\ %m\ %f:%l:%c"
  let l:listtype = go#list#Type("GoCyclo")
  call go#list#ParseFormat(l:listtype, errformat, l:out, 'Cyclomatic complexity', 0)

  let errors = go#list#Get(l:listtype)
  call go#list#Window(l:listtype, len(errors))
endfunction

" restore Vi compatibility settings
let &cpo = s:cpo_save
unlet s:cpo_save

" vim: sw=2 ts=2 et

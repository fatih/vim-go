" don't spam the user when Vim is started in Vi compatibility mode
let s:cpo_save = &cpo
set cpo&vim

function! go#staticcheck#Check(bang, ...) abort
  if a:0 == 0
    let l:import_path = go#package#ImportPath()
    if import_path == -1
      call go#util#EchoError('package is not inside GOPATH src')
      return
    endif
  else
    let l:import_path = join(a:000, ' ')
  endif

  call go#util#EchoProgress('[staticcheck] analysing ...')
  redraw

  let [l:out, l:err] = go#util#Exec([go#config#StaticcheckBin(), l:import_path])

  let l:listtype = go#list#Type("GoStaticCheck")
  if l:err != 0
    "" pwd/pkg/file.go:123:45: some reason for error (errcode)
    let errformat = "%f:%l:%c:\ %m\ (%t%n)"

    " Parse and populate our location list
    call go#list#ParseFormat(l:listtype, errformat, split(out, "\n"), 'StaticCheck')

    let l:errors = go#list#Get(l:listtype)
    if empty(l:errors)
      call go#util#EchoError(l:out)
      return
    endif

    if !empty(errors)
      call go#list#Populate(l:listtype, errors, 'StaticCheck')
      call go#list#Window(l:listtype, len(errors))
      if !a:bang
        call go#list#JumpToFirst(l:listtype)
      endif
    endif
  else
    call go#list#Clean(l:listtype)
    call go#util#EchoSuccess('[staticcheck] PASS')
  endif
endfunction

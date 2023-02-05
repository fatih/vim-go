" don't spam the user when Vim is started in Vi compatibility mode
let s:cpo_save = &cpo
set cpo&vim

func! Test_GoTermNewMode()
  if !(has('nvim') || has('terminal'))
    return
  endif

  try
    let g:go_gopls_enabled = 0
    let l:filename = 'term/term.go'
    let l:tmp = gotest#load_fixture(l:filename)
    call go#util#Chdir(l:tmp . '/src/term')

    let expected = expand('%:p')
    let l:winid = win_getid()

    let l:expectedwindows = len(getwininfo()) + 1

    let cmd = "go run ".  go#util#Shelljoin(go#tool#Files())

    set nosplitright

    let l:jobid = go#term#new(0, cmd, &errorformat)

    call go#job#Wait(l:jobid)

    let actual = expand('%:p')
    call assert_equal(actual, l:expected)
    call assert_equal(l:expectedwindows, len(getwininfo()))

  finally
    call win_gotoid(l:winid)
    only!
    call delete(l:tmp, 'rf')
  endtry
endfunc

func! Test_GoTermNewMode_SplitRight()
  if !(has('nvim') || has('terminal'))
    return
  endif

  try
    let g:go_gopls_enabled = 0
    let l:filename = 'term/term.go'
    let l:tmp = gotest#load_fixture(l:filename)
    call go#util#Chdir(l:tmp . '/src/term')

    let expected = expand('%:p')
    let l:winid = win_getid()

    let l:expectedwindows = len(getwininfo()) + 1

    let cmd = "go run ".  go#util#Shelljoin(go#tool#Files())

    set splitright

    let l:jobid = go#term#new(0, cmd, &errorformat)

    call go#job#Wait(l:jobid)

    let actual = expand('%:p')
    call assert_equal(actual, l:expected)
    call assert_equal(l:expectedwindows, len(getwininfo()))

  finally
    call win_gotoid(l:winid)
    only!
    call delete(l:tmp, 'rf')
    set nosplitright
  endtry
endfunc

func! Test_GoTermReuse()
  if !(has('nvim') || has('terminal'))
    return
  endif

  try
    let g:go_gopls_enabled = 0
    let l:filename = 'term/term.go'
    let l:tmp = gotest#load_fixture(l:filename)

    call go#util#Chdir(l:tmp . '/src/term')

    let l:winid = win_getid()
    let expected = expand('%:p')

    let l:expectedwindows = len(getwininfo())+1

    let cmd = "go run ".  go#util#Shelljoin(go#tool#Files())

    set nosplitright

    " prime the terminal window
    let l:jobid = go#term#new(0, cmd, &errorformat)

    call go#job#Wait(l:jobid)

    let g:go_term_reuse = 1

    let l:jobid = go#term#new(0, cmd, &errorformat)

    call go#job#Wait(l:jobid)

    let actual = expand('%:p')
    call assert_equal(actual, l:expected)
    call assert_equal(l:expectedwindows, len(getwininfo()))

    let l:jobid = go#term#new(0, cmd, &errorformat)

    call go#job#Wait(l:jobid)

    let actual = expand('%:p')
    call assert_equal(actual, l:expected)

    call assert_equal(l:expectedwindows, len(getwininfo()))

  finally
    call win_gotoid(l:winid)
    only!
    call delete(l:tmp, 'rf')
  endtry
endfunc

" restore Vi compatibility settings
let &cpo = s:cpo_save
unlet s:cpo_save

" vim: sw=2 ts=2 et

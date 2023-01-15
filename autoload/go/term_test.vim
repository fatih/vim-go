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

    call go#term#new(0, cmd, &errorformat)

    let l:start = reltime()
    while len(getwininfo()) < l:expectedwindows && reltimefloat(reltime(l:start)) < 10
      sleep 50m
    endwhile

    let actual = expand('%:p')
    call assert_equal(actual, l:expected)
    call assert_equal(l:expectedwindows, len(getwininfo()))

  finally
    call win_gotoid(l:winid)
    call delete(l:tmp, 'rf')
    unlet g:go_gopls_enabled
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

    call go#term#new(0, cmd, &errorformat)

    let l:start = reltime()
    while len(getwininfo()) < l:expectedwindows && reltimefloat(reltime(l:start)) < 10
      sleep 50m
    endwhile

    let actual = expand('%:p')
    call assert_equal(actual, l:expected)
    call assert_equal(l:expectedwindows, len(getwininfo()))

  finally
    call win_gotoid(l:winid)
    call delete(l:tmp, 'rf')
    set nosplitright
    unlet g:go_gopls_enabled
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

    let g:go_term_reuse = 1

    call go#term#new(0, cmd, &errorformat)

    let l:start = reltime()
    while len(getwininfo()) < l:expectedwindows && reltimefloat(reltime(l:start)) < 10
      sleep 50m
    endwhile

    let actual = expand('%:p')
    call assert_equal(actual, l:expected)
    call assert_equal(l:expectedwindows, len(getwininfo()))

    call go#term#new(0, cmd, &errorformat)

    let l:start = reltime()
    while len(getwininfo()) < l:expectedwindows && reltimefloat(reltime(l:start)) < 10
      sleep 50m
    endwhile

    let actual = expand('%:p')
    call assert_equal(actual, l:expected)

    call assert_equal(l:expectedwindows, len(getwininfo()))

  finally
    call win_gotoid(l:winid)
    unlet g:go_term_reuse
    call delete(l:tmp, 'rf')
    unlet g:go_gopls_enabled
  endtry
endfunc

" restore Vi compatibility settings
let &cpo = s:cpo_save
unlet s:cpo_save

" vim: sw=2 ts=2 et

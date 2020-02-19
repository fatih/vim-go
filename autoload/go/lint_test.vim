" don't spam the user when Vim is started in Vi compatibility mode
let s:cpo_save = &cpo
set cpo&vim

func! Test_GometaGolangciLint() abort
  call s:gometa('golangci-lint')
endfunc

func! s:gometa(metalinter) abort
  let RestoreGOPATH = go#util#SetEnv('GOPATH', fnamemodify(getcwd(), ':p') . 'test-fixtures/lint')
  silent exe 'e ' . $GOPATH . '/src/lint/lint.go'

  try
    let g:go_metalinter_command = a:metalinter
    let expected = [
          \ {'lnum': 5, 'bufnr': bufnr('%')+1, 'col': 1, 'valid': 1, 'vcol': 0, 'nr': -1, 'type': 'w', 'pattern': '', 'text': 'exported function MissingFooDoc should have comment or be unexported (golint)'}
        \ ]
    if a:metalinter == 'golangci-lint'
      let expected = [
            \ {'lnum': 5, 'bufnr': bufnr('%')+4, 'col': 1, 'valid': 1, 'vcol': 0, 'nr': -1, 'type': '', 'pattern': '', 'text': 'exported function `MissingFooDoc` should have comment or be unexported (golint)'}
          \ ]
    endif

    " clear the quickfix lists
    call setqflist([], 'r')

    let g:go_metalinter_enabled = ['golint']

    call go#lint#Gometa(0, 0, $GOPATH . '/src/foo')

    let actual = getqflist()
    let start = reltime()
    while len(actual) == 0 && reltimefloat(reltime(start)) < 10
      sleep 100m
      let actual = getqflist()
    endwhile

    call gotest#assert_quickfix(actual, expected)
  finally
      call call(RestoreGOPATH, [])
      unlet g:go_metalinter_enabled
  endtry
endfunc

func! Test_GometaGolangciLint_problems() abort
  call s:gometa_problems('golangci-lint')
endfunc

func! s:gometa_problems(metalinter) abort
  let RestoreGOPATH = go#util#SetEnv('GOPATH', fnamemodify(getcwd(), ':p') . 'test-fixtures/lint')
  silent exe 'e ' . $GOPATH . '/src/lint/golangci-lint/problems/problems.go'

  try
    let g:go_metalinter_command = a:metalinter
    let expected = [
          \ {'lnum': 3, 'bufnr': bufnr('%'), 'col': 8, 'pattern': '', 'valid': 1, 'vcol': 0, 'nr': -1, 'type': 'w', 'module': '', 'text': '[runner] Can''t run linter golint: golint: analysis skipped: errors in package'},
          \ {'lnum': 3, 'bufnr': bufnr('%'), 'col': 8, 'pattern': '', 'valid': 1, 'vcol': 0, 'nr': -1, 'type': 'e', 'module': '', 'text': 'Running error: golint: analysis skipped: errors in package'}
        \ ]

    " clear the quickfix lists
    call setqflist([], 'r')

    let g:go_metalinter_enabled = ['golint']

    call go#lint#Gometa(0, 0)

    let actual = getqflist()
    let start = reltime()
    while len(actual) == 0 && reltimefloat(reltime(start)) < 10
      sleep 100m
      let actual = getqflist()
    endwhile

    call gotest#assert_quickfix(actual, expected)
  finally
      call call(RestoreGOPATH, [])
      unlet g:go_metalinter_enabled
  endtry
endfunc

func! Test_GometaAutoSaveGolangciLint() abort
  call s:gometaautosave('golangci-lint', 0)
endfunc

func! Test_GometaAutoSaveKeepsErrors() abort
  call s:gometaautosave('golangci-lint', 1)
endfunc

func! s:gometaautosave(metalinter, withList) abort
  let RestoreGOPATH = go#util#SetEnv('GOPATH', fnameescape(fnamemodify(getcwd(), ':p')) . 'test-fixtures/lint')
  silent exe 'e ' . $GOPATH . '/src/lint/lint.go'

  try
    let g:go_metalinter_command = a:metalinter
    let l:expected = [
          \ {'lnum': 5, 'bufnr': bufnr('%'), 'col': 1, 'valid': 1, 'vcol': 0, 'nr': -1, 'type': 'w', 'pattern': '', 'text': 'exported function MissingDoc should have comment or be unexported (golint)'}
        \ ]
    if a:metalinter == 'golangci-lint'
      let l:expected = [
            \ {'lnum': 5, 'bufnr': bufnr('%'), 'col': 1, 'valid': 1, 'vcol': 0, 'nr': -1, 'type': '', 'pattern': '', 'text': 'exported function `MissingDoc` should have comment or be unexported (golint)'}
          \ ]
    endif

    let l:list = []
    if a:withList
      let l:list = [
            \ {'lnum': 1, 'bufnr': 1, 'col': 1, 'valid': 1, 'vcol': 0, 'nr': -1, 'type': '', 'pattern': '', 'text': 'before metalinter'}
          \ ]
      let l:expected = extend(l:list, l:expected)
    endif

    " set the location lists
    call setloclist(0, l:list, 'r')

    let g:go_metalinter_autosave_enabled = ['golint']

    call go#lint#Gometa(0, 1)

    let l:actual = getloclist(0)
    let l:start = reltime()
    while len(l:actual) != len(l:expected) && reltimefloat(reltime(l:start)) < 10
      sleep 100m
      let l:actual = getloclist(0)
    endwhile

    call gotest#assert_quickfix(l:actual, l:expected)
  finally
    call call(RestoreGOPATH, [])
    unlet g:go_metalinter_autosave_enabled
  endtry
endfunc

func! Test_GometaAutoSaveGolangciLint_problems() abort
  call s:gometaautosave_problems('golangci-lint')
endfunc

func! s:gometaautosave_problems(metalinter) abort
  let RestoreGOPATH = go#util#SetEnv('GOPATH', fnameescape(fnamemodify(getcwd(), ':p')) . 'test-fixtures/lint')
  silent exe 'e ' . $GOPATH . '/src/lint/golangci-lint/problems/ok.go'

  try
    let g:go_metalinter_command = a:metalinter
    let expected = [
          \ {'lnum': 3, 'bufnr': bufnr('%')+1, 'col': 8, 'pattern': '', 'valid': 1, 'vcol': 0, 'nr': -1, 'type': 'w', 'module': '', 'text': '[runner] Can''t run linter golint: golint: analysis skipped: errors in package'},
          \ {'lnum': 3, 'bufnr': bufnr('%')+1, 'col': 8, 'pattern': '', 'valid': 1, 'vcol': 0, 'nr': -1, 'type': 'e', 'module': '', 'text': 'Running error: golint: analysis skipped: errors in package'}
        \ ]

    " clear the location lists
    call setloclist(0, [], 'r')

    let g:go_metalinter_autosave_enabled = ['golint']

    call go#lint#Gometa(0, 1)

    let actual = getloclist(0)
    let start = reltime()
    while len(actual) == 0 && reltimefloat(reltime(start)) < 10
      sleep 100m
      let actual = getloclist(0)
    endwhile

    call gotest#assert_quickfix(actual, expected)
  finally
    call call(RestoreGOPATH, [])
    unlet g:go_metalinter_autosave_enabled
  endtry
endfunc

func! Test_Vet() abort
  let l:tmp = gotest#load_fixture('lint/src/vet/vet.go')

  try
    let expected = [
          \ {'lnum': 7, 'bufnr': bufnr('%')+2, 'col': 2, 'valid': 1, 'vcol': 0, 'nr': -1, 'type': '', 'pattern': '',
          \ 'text': 'Printf format %d has arg str of wrong type string'}
        \ ]

    let winnr = winnr()

    " clear the location lists
    call setqflist([], 'r')

    call go#lint#Vet(1)

    let actual = getqflist()
    let start = reltime()
    while len(actual) == 0 && reltimefloat(reltime(start)) < 10
      sleep 100m
      let actual = getqflist()
    endwhile

    call gotest#assert_quickfix(actual, expected)
  finally
    call delete(l:tmp, 'rf')
  endtry
endfunc

func! Test_Vet_compilererror() abort
  let l:tmp = gotest#load_fixture('lint/src/vet/compilererror/compilererror.go')

  try
    let expected = [
          \ {'lnum': 6, 'bufnr': bufnr('%')+2, 'col': 22, 'valid': 1, 'vcol': 0, 'nr': -1, 'type': '', 'pattern': '', 'text': "missing ',' before newline in argument list (and 1 more errors)"}
        \ ]

    let winnr = winnr()

    " clear the location lists
    call setqflist([], 'r')

    call go#lint#Vet(1)

    let actual = getqflist()
    let start = reltime()
    while len(actual) == 0 && reltimefloat(reltime(start)) < 10
      sleep 100m
      let actual = getqflist()
    endwhile

    call gotest#assert_quickfix(actual, expected)
  finally
    call delete(l:tmp, 'rf')
  endtry
endfunc

func! Test_Lint_GOPATH() abort
  let RestoreGOPATH = go#util#SetEnv('GOPATH', fnameescape(fnamemodify(getcwd(), ':p')) . 'test-fixtures/lint')

  silent exe 'e ' . $GOPATH . '/src/lint/lint.go'
  compiler go

  let expected = [
          \ {'lnum': 5, 'bufnr': bufnr('%'), 'col': 1, 'valid': 1, 'vcol': 0, 'nr': -1, 'type': '', 'pattern': '', 'text': 'exported function MissingDoc should have comment or be unexported'},
          \ {'lnum': 5, 'bufnr': bufnr('%')+5, 'col': 1, 'valid': 1, 'vcol': 0, 'nr': -1, 'type': '', 'pattern': '', 'text': 'exported function AlsoMissingDoc should have comment or be unexported'}
      \ ]

  let winnr = winnr()

  " clear the location lists
  call setqflist([], 'r')

  call go#lint#Golint(1)

  let actual = getqflist()
  let start = reltime()
  while len(actual) == 0 && reltimefloat(reltime(start)) < 10
    sleep 100m
    let actual = getqflist()
  endwhile

  call gotest#assert_quickfix(actual, expected)

  call call(RestoreGOPATH, [])
endfunc

func! Test_Lint_NullModule() abort
  silent exe 'e ' . fnameescape(fnamemodify(getcwd(), ':p')) . 'test-fixtures/lint/src/lint/lint.go'
  compiler go

  let expected = [
          \ {'lnum': 5, 'bufnr': bufnr('%'), 'col': 1, 'valid': 1, 'vcol': 0, 'nr': -1, 'type': '', 'pattern': '', 'text': 'exported function MissingDoc should have comment or be unexported'},
          \ {'lnum': 5, 'bufnr': bufnr('%')+5, 'col': 1, 'valid': 1, 'vcol': 0, 'nr': -1, 'type': '', 'pattern': '', 'text': 'exported function AlsoMissingDoc should have comment or be unexported'}
      \ ]

  let winnr = winnr()

  " clear the location lists
  call setqflist([], 'r')

  call go#lint#Golint(1)

  let actual = getqflist()
  let start = reltime()
  while len(actual) == 0 && reltimefloat(reltime(start)) < 10
    sleep 100m
    let actual = getqflist()
  endwhile

  call gotest#assert_quickfix(actual, expected)
endfunc

func! Test_Errcheck() abort
  let RestoreGOPATH = go#util#SetEnv('GOPATH', fnamemodify(getcwd(), ':p') . 'test-fixtures/lint')
  silent exe 'e ' . $GOPATH . '/src/errcheck/errcheck.go'

  try
    let l:bufnr = bufnr('')
    let expected = [
          \ {'lnum': 9, 'bufnr': bufnr(''), 'col': 9, 'pattern': '', 'valid': 1, 'vcol': 0, 'nr': -1, 'type': '', 'module': '', 'text': ":\tio.Copy(os.Stdout, os.Stdin)"},
          \ {'lnum': 10, 'bufnr': bufnr('')+1, 'col': 9, 'pattern': '', 'valid': 1, 'vcol': 0, 'nr': -1, 'type': '', 'module': '', 'text': ":\tio.Copy(os.Stdout, os.Stdin)"},
        \ ]

    " clear the location lists
    call setqflist([], 'r')

    call go#lint#Errcheck(1)

    call gotest#assert_quickfix(getqflist(), expected)
    call assert_equal(l:bufnr, bufnr(''))
  finally
    call call(RestoreGOPATH, [])
  endtry
endfunc

func! Test_Errcheck_options() abort
  let RestoreGOPATH = go#util#SetEnv('GOPATH', fnamemodify(getcwd(), ':p') . 'test-fixtures/lint')
  silent exe 'e ' . $GOPATH . '/src/errcheck/errcheck.go'

  try
    let l:bufnr = bufnr('')
    let expected = [
          \ {'lnum': 9, 'bufnr': bufnr(''), 'col': 9, 'pattern': '', 'valid': 1, 'vcol': 0, 'nr': -1, 'type': '', 'module': '', 'text': ":\tio.Copy(os.Stdout, os.Stdin)"},
        \ ]

    " clear the location lists
    call setqflist([], 'r')

    call go#lint#Errcheck(1, '-ignoretests')

    call gotest#assert_quickfix(getqflist(), expected)
    call assert_equal(l:bufnr, bufnr(''))
  finally
    call call(RestoreGOPATH, [])
  endtry
endfunc

func! Test_Errcheck_compilererror() abort
  let l:tmp = gotest#load_fixture('lint/src/errcheck/compilererror/compilererror.go')

  try
    let l:bufnr = bufnr('')
    let expected = []

    " clear the location lists
    call setqflist([], 'r')

    call go#lint#Errcheck(1)

    call gotest#assert_quickfix(getqflist(), expected)
    call assert_equal(l:bufnr, bufnr(''))
  finally
    call delete(l:tmp, 'rf')
  endtry
endfunc

" restore Vi compatibility settings
let &cpo = s:cpo_save
unlet s:cpo_save

" vim: sw=2 ts=2 et

func! Test_GoTest() abort
  let expected = [
        \ {'lnum': 12, 'bufnr': 2, 'col': 0, 'valid': 1, 'vcol': 0, 'nr': -1, 'type': '', 'pattern': '', 'text': 'log message'},
        \ {'lnum': 13, 'bufnr': 2, 'col': 0, 'valid': 1, 'vcol': 0, 'nr': -1, 'type': '', 'pattern': '', 'text': 'sub badness'},
        \ {'lnum': 15, 'bufnr': 2, 'col': 0, 'valid': 1, 'vcol': 0, 'nr': -1, 'type': '', 'pattern': '', 'text': 'badness'},
        \ {'lnum': 16, 'bufnr': 2, 'col': 0, 'valid': 1, 'vcol': 0, 'nr': -1, 'type': '', 'pattern': '', 'text': 'helper badness'},
        \ {'lnum': 20, 'bufnr': 2, 'col': 0, 'valid': 1, 'vcol': 0, 'nr': -1, 'type': '', 'pattern': '', 'text': 'this is an error'},
        \ {'lnum': 0, 'bufnr': 0, 'col': 0, 'valid': 1, 'vcol': 0, 'nr': -1, 'type': '', 'pattern': '', 'text': 'and a second line, too'},
        \ {'lnum': 25, 'bufnr': 2, 'col': 0, 'valid': 1, 'vcol': 0, 'nr': -1, 'type': '', 'pattern': '', 'text': 'this is a sub-test error'},
        \ {'lnum': 0, 'bufnr': 0, 'col': 0, 'valid': 1, 'vcol': 0, 'nr': -1, 'type': '', 'pattern': '', 'text': 'and a second line, too'},
        \ {'lnum': 6, 'bufnr': 3, 'col': 0, 'valid': 1, 'vcol': 0, 'nr': -1, 'type': '', 'pattern': '', 'text': 'another package badness'},
        \ {'lnum': 42, 'bufnr': 2, 'col': 0, 'valid': 1, 'vcol': 0, 'nr': -1, 'type': '', 'pattern': '', 'text': 'panic: worst ever [recovered]'}
      \ ]
  call s:test('play/play_test.go', expected)

endfunc

func! Test_GoTestConcurrentPanic()
  let expected = [
        \ {'lnum': 49, 'bufnr': 2, 'col': 0, 'valid': 1, 'vcol': 0, 'nr': -1, 'type': '', 'pattern': '', 'text': 'panic: concurrent fail'}
      \ ]
  call s:test('play/play_test.go', expected, "-run", "TestConcurrentPanic")
endfunc

func! Test_GoTestVerbose() abort
  let expected = [
        \ {'lnum': 12, 'bufnr': 2, 'col': 0, 'valid': 1, 'vcol': 0, 'nr': -1, 'type': '', 'pattern': '', 'text': 'log message'},
        \ {'lnum': 13, 'bufnr': 2, 'col': 0, 'valid': 1, 'vcol': 0, 'nr': -1, 'type': '', 'pattern': '', 'text': 'sub badness'},
        \ {'lnum': 15, 'bufnr': 2, 'col': 0, 'valid': 1, 'vcol': 0, 'nr': -1, 'type': '', 'pattern': '', 'text': 'badness'},
        \ {'lnum': 16, 'bufnr': 2, 'col': 0, 'valid': 1, 'vcol': 0, 'nr': -1, 'type': '', 'pattern': '', 'text': 'helper badness'},
        \ {'lnum': 20, 'bufnr': 2, 'col': 0, 'valid': 1, 'vcol': 0, 'nr': -1, 'type': '', 'pattern': '', 'text': 'this is an error'},
        \ {'lnum': 0, 'bufnr': 0, 'col': 0, 'valid': 1, 'vcol': 0, 'nr': -1, 'type': '', 'pattern': '', 'text': 'and a second line, too'},
        \ {'lnum': 25, 'bufnr': 2, 'col': 0, 'valid': 1, 'vcol': 0, 'nr': -1, 'type': '', 'pattern': '', 'text': 'this is a sub-test error'},
        \ {'lnum': 0, 'bufnr': 0, 'col': 0, 'valid': 1, 'vcol': 0, 'nr': -1, 'type': '', 'pattern': '', 'text': 'and a second line, too'},
        \ {'lnum': 31, 'bufnr': 2, 'col': 0, 'valid': 1, 'vcol': 0, 'nr': -1, 'type': '', 'pattern': '', 'text': 'goodness'},
        \ {'lnum': 6, 'bufnr': 3, 'col': 0, 'valid': 1, 'vcol': 0, 'nr': -1, 'type': '', 'pattern': '', 'text': 'another package badness'},
        \ {'lnum': 42, 'bufnr': 2, 'col': 0, 'valid': 1, 'vcol': 0, 'nr': -1, 'type': '', 'pattern': '', 'text': 'panic: worst ever [recovered]'}
      \ ]
  call s:test('play/play_test.go', expected, "-v")
endfunc

func! Test_GoTestCompilerError() abort
  let expected = [
        \ {'lnum': 6, 'bufnr': 6, 'col': 22, 'valid': 1, 'vcol': 0, 'nr': -1, 'type': '', 'pattern': '', 'text': 'syntax error: unexpected newline, expecting comma or )'}
      \ ]

  call s:test('compilerror/compilerror_test.go', expected)
endfunc

func! Test_GoTestTimeout() abort
  let expected = [
        \ {'lnum': 0, 'bufnr': 0, 'col': 0, 'valid': 1, 'vcol': 0, 'nr': -1, 'type': '', 'pattern': '', 'text': 'panic: test timed out after 500ms'}
      \ ]

  let g:go_test_timeout="500ms"
  call s:test('timeout/timeout_test.go', expected)
  unlet g:go_test_timeout
endfunc

func! s:test(file, expected, ...) abort
  if has('nvim')
    " nvim mostly shows test errors correctly, but the the expected errors are
    " slightly different; buffer numbers are not the same and stderr doesn't
    " seem to be redirected to the job, so the lines from the panic aren't in
    " the output to be parsed, and hence are not in the quickfix lists. Once
    " those two issues are resolved, this early return should be removed so
    " the tests will run for Neovim, too.
    return
  endif
  let $GOPATH = fnameescape(expand("%:p:h")) . '/test-fixtures/test'
  silent exe 'e ' . $GOPATH . '/src/' . a:file

  " clear the quickfix lists
  call setqflist([], 'r')

  let args = [1,0]
  if a:0
    let args += a:000
  endif

  " run the tests
  call call(function('go#test#Test'), args)

  let actual = getqflist()
  let start = reltime()
  while len(actual) == 0 && reltimefloat(reltime(start)) < 10
    sleep 100m
    let actual = getqflist()
  endwhile

  " for some reason, when run headless, the quickfix lists includes a line
  " that should have been filtered out; remove it manually. The line is not
  " present when run manually.
  let i = 0
  while i < len(actual)
    if actual[i].text =~# '^=== RUN   .*'
      call remove(actual, i)
    endif
    let i += 1
  endwhile

  call assert_equal(len(a:expected), len(actual), "number of errors")
  if len(a:expected) != len(actual)
    return
  endif

  let i = 0
  while i < len(a:expected)
    let expected_item = a:expected[i]
    let actual_item = actual[i]
    let i += 1

    call assert_equal(expected_item.bufnr, actual_item.bufnr, "bufnr")
    call assert_equal(expected_item.lnum, actual_item.lnum, "lnum")
    call assert_equal(expected_item.col, actual_item.col, "col")
    call assert_equal(expected_item.vcol, actual_item.vcol, "vcol")
    call assert_equal(expected_item.nr, actual_item.nr, "nr")
    call assert_equal(expected_item.pattern, actual_item.pattern, "pattern")

    let expected_text = s:normalize_durations(expected_item.text)
    let actual_text = s:normalize_durations(actual_item.text)

    call assert_equal(expected_text, actual_text, "text")
    call assert_equal(expected_item.type, actual_item.type, "type")
    call assert_equal(expected_item.valid, actual_item.valid, "valid")
  endwhile
endfunc

func! s:normalize_durations(str) abort
  return substitute(a:str, '[0-9]\+\(\.[0-9]\+\)\?s', '0.000s', 'g')
endfunc

" vim: sw=2 ts=2 et

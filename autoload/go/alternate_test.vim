fun! Test_Alternate() abort
  let l:cases = [
    \ {
        \ 'start':   'notest.go',
        \ 'want':    'notest.go',
        \ 'wantErr': "couldn't find notest_test.go",
    \ },
    \ {
        \ 'start':   'nomain_test.go',
        \ 'want':    'nomain_test.go',
        \ 'wantErr': "couldn't find nomain.go",
    \ },
    \ {
        \ 'start':   'bang.go',
        \ 'want':    'bang_test.go',
        \ 'wantErr': 0,
        \ 'bang':    1,
    \ },
    \ {
        \ 'start':   'f.go',
        \ 'want':    'f_test.go',
        \ 'wantErr': 0,
        \ 'run':     'e f_test.go | silent noau w'
    \ },
    \ {
        \ 'start':   'space path/a_test.go',
        \ 'want':    'space path/a.go',
        \ 'wantErr': 0,
        \ 'run':     'call mkdir("space path") | e space\ path/a.go | silent noau w'
    \ },
  \ ]

  for l:tc in l:cases
    exe 'lcd ' . gotest#dir('', 1)

    try
      if get(l:tc, 'run', '') isnot# ''
        exe l:tc.run
      endif

      exe 'e ' . gotest#dir(l:tc.start, 1)
      silent call go#alternate#Switch(get(l:tc, 'bang', 0), '')
      call assert_equal(l:tc.want, bufname('%'))
      call assert_equal(l:tc.wantErr, gotest#lastmsg())
    finally
      let g:go_messages = []
    endtry
  endfor
endfun

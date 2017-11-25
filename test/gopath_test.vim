fun! Test_Detect_Gopath() abort
  try
    let g:go_autodetect_gopath = 1
    let l:tmp = '/tmp/vim-go-test/testrun/gp'
    call mkdir(l:tmp . '/Godeps/_workspace', 'p')

    let $GOPATH = l:tmp
    e /tmp/vim-go-test/testrun/gp/a.go
    call assert_equal(l:tmp . '/Godeps/_workspace:' . l:tmp, $GOPATH)

    exe 'e ' l:tmp . '/x'
    call assert_equal(l:tmp, $GOPATH)
  finally
    let g:go_autodetect_gopath = 0
    call delete(l:tmp, 'rf')
  endtry
endfun

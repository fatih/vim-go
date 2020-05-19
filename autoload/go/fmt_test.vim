" don't spam the user when Vim is started in Vi compatibility mode
let s:cpo_save = &cpo
set cpo&vim

func! Test_run_fmt() abort
  let input_file = "test-fixtures/fmt/hello.go"
  let actual = join(go#fmt#run(-1, readfile(input_file), input_file), "\n")

  let expected = join(readfile("test-fixtures/fmt/hello_golden.go"), "\n")

  call assert_equal(expected, actual)
endfunc

func! Test_goimports() abort
  let $GOPATH = 'test-fixtures/fmt/'

  let input_file = "test-fixtures/fmt/src/imports/goimports.go"
  let actual = join(go#fmt#run(1, readfile(input_file), input_file), "\n")

  let expected = join(readfile("test-fixtures/fmt/src/imports/goimports_golden.go"), "\n")

  call assert_equal(expected, actual)
endfunc

" restore Vi compatibility settings
let &cpo = s:cpo_save
unlet s:cpo_save

" vim: sw=2 ts=2 et

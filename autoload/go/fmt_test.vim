func Test_run_fmt()
  let actual_file = tempname()
  call writefile(readfile("test-fixtures/fmt/hello.go"), actual_file)

  let expected = join(readfile("test-fixtures/fmt/hello_golden.go"), "\n")

  " run our code
  call go#fmt#run("gofmt", actual_file, "test-fixtures/fmt/hello.go")

  " this should now contain the formatted code
  let actual = join(readfile(actual_file), "\n")

  call assert_equal(expected, actual)
endfunc

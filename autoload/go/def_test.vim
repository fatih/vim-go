func! Test_jump_to_declaration_guru() abort
  try
    let l:tmp = gotest#loadFile('a/a.go', [
          \ 'package main',
          \ '',
          \ 'import "fmt"',
          \ '',
          \ 'func main() {',
          \ '    fmt.Println("vim-go")',
          \ '}'])

    let filename = 'a/a.go'
    let lnum = 5
    let col = 6

    let guru_out = printf("%s:%d:%d: defined here as func main", filename, lnum, col)
    call go#def#jump_to_declaration(guru_out, "", 'guru')

    call assert_equal(filename, bufname("%"))
    call assert_equal(lnum, getcurpos()[1])
    call assert_equal(col, getcurpos()[2])
  finally
    call delete(l:tmp, 'rf')
  endtry
endfunc

func! Test_jump_to_declaration_godef() abort
  try
    let l:tmp = gotest#loadFile('a/a.go', [
          \ 'package main',
          \ '',
          \ 'import "fmt"',
          \ '',
          \ 'func main() {',
          \ '    fmt.Println("vim-go")',
          \ '}'])

    let filename = 'a/a.go'
    let lnum = 5
    let col = 6

    let godef_out = printf("%s:%d:%d\ndefined here as func main", filename, lnum, col)
    call go#def#jump_to_declaration(godef_out, "", 'godef')

    call assert_equal(filename, bufname("%"))
    call assert_equal(lnum, getcurpos()[1])
    call assert_equal(col, getcurpos()[2])
  finally
    call delete(l:tmp, 'rf')
  endtry
endfunc

" vim: sw=2 ts=2 et

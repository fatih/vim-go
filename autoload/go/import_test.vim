func! Test_import() abort
  try
    let l:tmp = gotest#write_file('a/a.go', [
          \ 'package a',
          \ '',
          \ 'import "fmt"',
          \ '',
          \ 'func main() { fmt.Println("foo") }'])

    call go#import#SwitchImport(1, '', 'errors', 0)
    call gotest#assert_buffer(0, [
          \ 'package a',
          \ 'import (',
          \ '	"fmt"',
          \ '	"errors"',
          \ ')',
          \ '',
          \ 'func main() { fmt.Println("foo") }'])
  finally
    call delete(l:tmp, 'rf')
  endtry
endfunc

func! Test_import_new() abort
  try
    let l:tmp = gotest#write_file('a/a.go', [
          \ 'package a',
          \ '',
          \ 'func main() { fmt.Println("foo") }'])

    call go#import#SwitchImport(1, '', 'errors', 0)
    call gotest#assert_buffer(0, [
          \ 'package a',
          \ 'import "errors"',
          \ 'func main() { fmt.Println("foo") }'])
  finally
    call delete(l:tmp, 'rf')
  endtry
endfunc

func! Test_drop() abort
  try
    let l:tmp = gotest#write_file('a/a.go', [
          \ 'package a',
          \ '',
          \ 'import (',
          \ '  "fmt"',
          \ '  "errors"',
          \ ')',
          \ '',
          \ 'func main() { fmt.Println("foo") }'])

    call go#import#SwitchImport(0, '', 'errors', 0)
    call gotest#assert_buffer(0, [
          \ 'package a',
          \ '',
          \ 'import "fmt"',
          \ '',
          \ 'func main() { fmt.Println("foo") }'])
  finally
    call delete(l:tmp, 'rf')
  endtry
endfunc


" vim: sw=2 ts=2 et

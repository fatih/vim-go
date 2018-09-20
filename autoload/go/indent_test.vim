func! Test_indent_raw_string() abort
  try
    let l:dir= gotest#write_file('indent/indent.go', [
          \ 'package main',
          \ '',
          \ 'import "fmt"',
          \ '',
          \ 'func main() {',
          \	"\t\x1fconst msg = `",
          \ '`',
          \ '\tfmt.Println(msg)',
          \ '}'])

    silent execute "normal o" . "not indented\<Esc>"
    let l:indent = indent(line('.'))
    call assert_equal(0, l:indent)
  finally
    call delete(l:dir, 'rf')
  endtry
endfunc

" Test scenarios where indentation should or shouldn't change when inside a
" matching pair of parens, braces, etc.
func! Test_indent_in_pair() abort
  try
    let l:dir = gotest#write_file('indent/indent.go', [
          \ 'package main',
          \ '',
          \ 'import "fmt"',
          \ '',
          \ "func main() {\x1f",
          \ '}'])

    " The indentation of a function call inside a function.
    let l:orig_indent = shiftwidth()

    " If we open a line in the middle of a function call, make sure that we
    " indent on the next line.
    silent execute "normal o" . "fmt.Println("
    silent execute "normal o" . "arg1)"
    let l:indent = indent(line('.'))
    call assert_equal(l:indent, l:orig_indent + shiftwidth())

    " If we open a line after a function call that was split over multiple
    " lines, the next line should be back to the original indent.
    silent execute "normal o" . "fmt.Println(whatever)"
    let l:indent = indent(line('.'))
    call assert_equal(l:indent, l:orig_indent)

    " If we open a line in the middle of a function call, make sure that we
    " indent even if the opening line of the function call doesn't end with the
    " parenthesis.
    silent execute "normal di{k" | " reset the function body
    silent execute "normal o" . "fmt.Println(arg1,"
    silent execute "normal o" . "arg2)"
    let l:indent = indent(line('.'))
    call assert_equal(l:indent, l:orig_indent + shiftwidth())

    " If we open a line inside a comment, we should ignore any pairs.
    " The comment discovery requires that syntax be enabled.
    silent execute "normal di{k" | " reset the function body
    syntax on
    silent execute "normal o" . "// Comment has a paren (which should"
    silent execute "normal o" . "// not cause further indentation)"
    syntax off
    let l:indent = indent(line('.'))
    call assert_equal(l:indent, l:orig_indent)
  finally
    call delete(l:dir, 'rf')
  endtry
endfunc

" vim: sw=2 ts=2 et

" don't spam the user when Vim is started in Vi compatibility mode
let s:cpo_save = &cpo
set cpo&vim

scriptencoding utf-8

func! Test_jump_to_declaration_godef() abort
  let l:wd = getcwd()
  try
    let g:go_gopls_enabled = 0
    let l:filename = 'def/jump.go'
    let l:lnum = 5
    let l:col = 6
    let l:tmp = gotest#load_fixture(l:filename)

    let l:godef_out = printf("%s:%d:%d\ndefined here as func main", l:filename, l:lnum, l:col)
    call go#def#jump_to_declaration(godef_out, "", 'godef')

    call assert_equal(l:filename, bufname("%"))
    call assert_equal(l:lnum, getcurpos()[1])
    call assert_equal(l:col, getcurpos()[2])
  finally
    call go#util#Chdir(l:wd)
    call delete(l:tmp, 'rf')
  endtry
endfunc

func! Test_Jump_leaves_lists() abort
  let l:wd = getcwd()
  try
    let l:filename = 'def/jump.go'
    let l:tmp = gotest#load_fixture(l:filename)

    let l:expected = [{'lnum': 10, 'bufnr': bufnr('%'), 'col': 1, 'valid': 1, 'vcol': 0, 'nr': -1, 'type': '', 'pattern': '', 'text': 'quux'}]

    call setloclist(0, copy(l:expected), 'r' )
    call setqflist(copy(l:expected), 'r' )

    let l:bufnr = bufnr('%')
    call cursor(6, 7)
   
    if !go#util#has_job()
      let g:go_def_mode='godef'
    endif
    call go#def#Jump('', 0)

    if !go#util#has_job()
    endif

    let l:start = reltime()
    while bufnr('%') == l:bufnr && reltimefloat(reltime(l:start)) < 10
      sleep 100m
    endwhile

    let l:actual = getloclist(0)
    call gotest#assert_quickfix(l:actual, l:expected)

    let l:actual = getqflist()
    call gotest#assert_quickfix(l:actual, l:expected)
  finally
    call go#util#Chdir(l:wd)
    call delete(l:tmp, 'rf')
  endtry
endfunc

func! Test_DefJump_gopls_simple_first() abort
  if !go#util#has_job()
    return
  endif

  let l:wd = getcwd()
  try
    let g:go_def_mode = 'gopls'

    let l:tmp = gotest#write_file('simple/firstposition/firstposition.go', [
          \ 'package firstposition',
          \ '',
          \ 'func Example() {',
          \ "\tid := " . '"foo"',
          \ "\tprintln(" . '"id:", id)',
          \ '}',
          \ ] )

    let l:expected = [0, 4, 2, 0]

    call assert_notequal(l:expected, getpos('.'))

    call go#def#Jump('', 0)

    let l:start = reltime()
    while getpos('.') != l:expected && reltimefloat(reltime(l:start)) < 10
      sleep 100m
    endwhile

    call assert_equal(l:expected, getpos('.'))
  finally
    call go#util#Chdir(l:wd)
    call delete(l:tmp, 'rf')
  endtry
endfunc

func! Test_DefJump_gopls_simple_last() abort
  if !go#util#has_job()
    return
  endif

  let l:wd = getcwd()
  try
    let g:go_def_mode = 'gopls'

    let l:tmp = gotest#write_file('simple/lastposition/lastposition.go', [
          \ 'package lastposition',
          \ '',
          \ 'func Example() {',
          \ "\tid := " . '"foo"',
          \ "\tprintln(" . '"id:", id)',
          \ '}',
          \ ] )

    let l:expected = [0, 4, 2, 0]

    call assert_notequal(l:expected, getpos('.'))

    call go#def#Jump('', 0)

    let l:start = reltime()
    while getpos('.') != l:expected && reltimefloat(reltime(l:start)) < 10
      sleep 100m
    endwhile

    call assert_equal(l:expected, getpos('.'))
  finally
    call go#util#Chdir(l:wd)
    call delete(l:tmp, 'rf')
  endtry
endfunc

func! Test_DefJump_gopls_MultipleCodeUnit_first() abort
  if !go#util#has_job()
    return
  endif

  let l:wd = getcwd()
  try
    let g:go_def_mode = 'gopls'

    let l:tmp = gotest#write_file('multiplecodeunit/firstposition/firstposition.go', [
          \ 'package firstposition',
          \ '',
          \ 'func Example() {',
          \ "\t𐐀, id := " . '"foo", "bar"',
          \ "\tprintln(" . '"(𐐀, id):", 𐐀, id)',
          \ '}',
          \ ] )

    let l:expected = [0, 4, 8, 0]
    call assert_notequal(l:expected, getpos('.'))

    call go#def#Jump('', 0)

    let l:start = reltime()
    while getpos('.') != l:expected && reltimefloat(reltime(l:start)) < 10
      sleep 100m
    endwhile

    call assert_equal(l:expected, getpos('.'))
  finally
    call go#util#Chdir(l:wd)
    call delete(l:tmp, 'rf')
  endtry
endfunc


func! Test_DefJump_gopls_MultipleCodeUnit_last() abort
  if !go#util#has_job()
    return
  endif

  let l:wd = getcwd()
  try
    let g:go_def_mode = 'gopls'

    let l:tmp = gotest#write_file('multiplecodeunit/lastposition/lastposition.go', [
          \ 'package lastposition',
          \ '',
          \ 'func Example() {',
          \ "\t𐐀, id := " . '"foo", "bar"',
          \ "\tprintln(" . '"(𐐀, id):", 𐐀, id)',
          \ '}',
          \ ] )

    let l:expected = [0, 4, 8, 0]
    call assert_notequal(l:expected, getpos('.'))

    call go#def#Jump('', 0)

    let l:start = reltime()
    while getpos('.') != l:expected && reltimefloat(reltime(l:start)) < 10
      sleep 100m
    endwhile

    call assert_equal(l:expected, getpos('.'))
  finally
    call go#util#Chdir(l:wd)
    call delete(l:tmp, 'rf')
  endtry
endfunc

func! Test_DefStackPop() abort
  if !go#util#has_job()
    return
  endif

  let l:wd = getcwd()
  try
    let g:go_def_mode = 'gopls'

    let l:tmp = gotest#write_file('defstack/pop/pop.go', [
          \ 'package pop',
          \ '',
          \ 'func Example() {',
          \ "\t\x1fcallee()",
          \ '}',
          \ '',
          \ 'func callee() {',
          \ '}',
          \ ] )

    let l:from = getpos('.')
    let l:expected = [0, 7, 6, 0]

    call go#def#Jump('', 0)

    let l:start = reltime()
    while getpos('.') != l:expected && reltimefloat(reltime(l:start)) < 10
      sleep 100m
    endwhile

    call assert_equal(l:expected, getpos('.'))

    " popping the stack should return to the position that the jump was made
    " from.
    call go#def#StackPop()

    call assert_equal(l:from, getpos('.'))
  finally
    call go#util#Chdir(l:wd)
    call delete(l:tmp, 'rf')
  endtry
endfunc

func! Test_DefStackClear() abort
  if !go#util#has_job()
    return
  endif

  let l:wd = getcwd()
  try
    let g:go_def_mode = 'gopls'

    let l:tmp = gotest#write_file('defstack/clear/clear.go', [
          \ 'package clear',
          \ '',
          \ 'func Example() {',
          \ "\t\x1fcallee()",
          \ '}',
          \ '',
          \ 'func callee() {',
          \ '}',
          \ ] )

    let l:expected = [0, 7, 6, 0]

    call go#def#Jump('', 0)

    let l:start = reltime()
    while getpos('.') != l:expected && reltimefloat(reltime(l:start)) < 10
      sleep 100m
    endwhile

    call assert_equal(l:expected, getpos('.'))

    " once the stack has been cleared, there's nowhere to pop back to, so the
    " cursor should not move.
    call go#def#StackClear()
    call go#def#StackPop()

    call assert_equal(l:expected, getpos('.'))
  finally
    call go#util#Chdir(l:wd)
    call delete(l:tmp, 'rf')
  endtry
endfunc

" restore Vi compatibility settings
let &cpo = s:cpo_save
unlet s:cpo_save

" vim: sw=2 ts=2 et

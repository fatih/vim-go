" add vim-go the only plugin inside the runtimepath
"
let total_started = reltime()

let git_root_path = system("git rev-parse --show-toplevel | tr -d '\\n'")
exe 'set rtp=' . git_root_path

" source test files
for s:vim_file in globpath(git_root_path . "/autoload/go", "*.vim", 0, 1)
  if s:vim_file =~# '^\f\+_test\.vim$'
    exec 'source ' . s:vim_file
  endif
endfor

let s:fail = 0
let s:done = 0
let s:errors = []
let s:messages = []

" get a list of all Test_ functions (sourced above)
set nomore
redir @q
silent function /^Test_
redir END
let s:tests = split(substitute(@q, 'function \(\k*()\)', '\1', 'g'))


" cd into autoload/go directory for tests
let cd = exists('*haslocaldir') && haslocaldir() ? 'lcd ' : 'cd '
let dir = getcwd()
execute cd . fnameescape(git_root_path."/autoload/go")

" Iterate over all tests and execute them
for s:test in sort(s:tests)
  let started = reltime()

  exe 'call ' . s:test

  let elapsed_time = reltimestr(reltime(started))
  let elapsed_time = substitute(elapsed_time, '^\s*\(.\{-}\)\s*$', '\1', '')

  call add(s:messages, printf("=== %s (%ss)", s:test, elapsed_time))

  let s:done += 1

  if len(v:errors) > 0
    let s:fail += 1
    call add(s:errors, 'Found errors in ' . s:test . ':')
    call extend(s:errors, v:errors)
    let v:errors = []
  endif
endfor

execute cd . fnameescape(dir)

if len(s:errors) > 0 || s:done == 0
  " Append errors to test.log
  split test.log
  call append(line('$'), '')
  call append(line('$'), s:errors)
  write
endif

let total_elapsed_time = reltimestr(reltime(total_started))
let total_elapsed_time = substitute(total_elapsed_time, '^\s*\(.\{-}\)\s*$', '\1', '')

let message = 'Executed ' . s:done . (s:done > 1 ? ' tests' : ' test') . '. Total test time: '. total_elapsed_time .'s'
call add(s:messages, "")
call add(s:messages, message)


split messages.log
call append(line('$'), '')
call append(line('$'), s:messages)
write

" bye, bye!
qall!

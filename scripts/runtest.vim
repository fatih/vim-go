let total_started = reltime()

" source the passed test file
source %

" cd into the folder of the test file
let cd = exists('*haslocaldir') && haslocaldir() ? 'lcd ' : 'cd '
let dir = getcwd()
let testfile = expand('%:t')
execute cd . expand('%:p:h')

" initialize variables
let s:fail = 0
let s:done = 0
let s:logs = []

" get a list of all Test_ functions for the given file
set nomore
redir @q
  silent function /^Test_
redir END
let s:tests = split(substitute(@q, 'function \(\k*()\)', '\1', 'g'))

" Iterate over all tests and execute them
for s:test in sort(s:tests)
  let started = reltime()

  call add(s:logs, printf("=== RUN  %s", s:test[:-3]))
  exe 'call ' . s:test

  let elapsed_time = reltimestr(reltime(started))
  let elapsed_time = substitute(elapsed_time, '^\s*\(.\{-}\)\s*$', '\1', '')

  let s:done += 1

  if len(v:errors) > 0
    let s:fail += 1
    call add(s:logs, printf("--- FAIL %s (%ss)", s:test[:-3], elapsed_time))
    call extend(s:logs, map(v:errors, '"        ".  v:val'))

    " reset so we can capture failures of next test
    let v:errors = []
  else
    call add(s:logs, printf("--- PASS %s (%ss)", s:test[:-3], elapsed_time))
  endif
endfor

" pop out into the scripts folder
execute cd . fnameescape(dir)

" create an empty fail to indicate that the test failed
if s:fail > 0
  split /tmp/vim-go-test/FAILED
  silent write
endif

let total_elapsed_time = reltimestr(reltime(total_started))
let total_elapsed_time = substitute(total_elapsed_time, '^\s*\(.\{-}\)\s*$', '\1', '')

" Add all messages (usually errors).
redir => s:mess
  silent messages
redir END
let s:logs = s:logs + filter(split(s:mess, "\n"), 'v:val !~ "^Messages maintainer"')

" Also store all internal messages from s:logs as well.
silent! split /tmp/vim-go-test/test.tmp
call append(line('$'), s:logs)
call append(line('$'), printf("%s%s       %s / %s tests",
      \ (s:fail > 0 ? 'FAIL     ' : 'ok       '),
      \ testfile, total_elapsed_time, s:done))
silent! write

qall!

" vim:ts=2:sts=2:sw=2:et

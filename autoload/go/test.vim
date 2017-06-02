" Test runs `go test` in the current directory. If compile is true, it'll
" compile the tests instead of running them (useful to catch errors in the
" test files). Any other argument is appendend to the final `go test` command
function! go#test#Test(bang, compile, ...) abort
  let args = ["test"]

  " don't run the test, only compile it. Useful to capture and fix errors.
  if a:compile
    let compile_file = "vim-go-test-compile"
    call extend(args, ["-c", "-o", compile_file])
  endif

  if a:0
    let goargs = a:000

    " do not expand for coverage mode as we're passing the arg ourself
    if a:1 != '-coverprofile'
      " expand all wildcards(i.e: '%' to the current file name)
      let goargs = map(copy(a:000), "expand(v:val)")
    endif

    if !(has('nvim') || go#util#has_job())
      let goargs = go#util#Shelllist(goargs, 1)
    endif

    call extend(args, goargs, 1)
  else
    " only add this if no custom flags are passed
    let timeout  = get(g:, 'go_test_timeout', '10s')
    call add(args, printf("-timeout=%s", timeout))
  endif

  if get(g:, 'go_echo_command_info', 1)
    if a:compile
      echon "vim-go: " | echohl Identifier | echon "compiling tests ..." | echohl None
    else
      echon "vim-go: " | echohl Identifier | echon "testing ..." | echohl None
    endif
  endif

  if go#util#has_job()
    " use vim's job functionality to call it asynchronously
    let job_args = {
          \ 'cmd': ['go'] + args,
          \ 'bang': a:bang,
          \ }

    if a:compile
      let job_args['custom_cb'] = function('s:test_compile', [compile_file])
    endif

    call s:test_job(job_args)
    return
  elseif has('nvim')
    " use nvims's job functionality
    if get(g:, 'go_term_enabled', 0)
      let id = go#term#new(a:bang, ["go"] + args)
    else
      let id = go#jobcontrol#Spawn(a:bang, "test", args)
    endif

    if a:compile
      call go#jobcontrol#AddHandler(function('s:test_compile_handler'))
      let s:test_compile_handlers[id] = compile_file
    endif
    return id
  endif

  call go#cmd#autowrite()
  redraw

  let command = "go " . join(args, ' ')
  let out = go#tool#ExecuteInDir(command)

  let l:listtype = "quickfix"

  let cd = exists('*haslocaldir') && haslocaldir() ? 'lcd ' : 'cd '
  let dir = getcwd()
  execute cd fnameescape(expand("%:p:h"))

  if a:compile
    call delete(compile_file)
  endif

  if go#util#ShellError() != 0
    let errors = go#tool#ParseErrors(split(out, '\n'))
    let errors = go#tool#FilterValids(errors)

    call go#list#Populate(l:listtype, errors, command)
    call go#list#Window(l:listtype, len(errors))
    if !empty(errors) && !a:bang
      call go#list#JumpToFirst(l:listtype)
    elseif empty(errors)
      " failed to parse errors, output the original content
      call go#util#EchoError(out)
    endif
    echon "vim-go: " | echohl ErrorMsg | echon "[test] FAIL" | echohl None
  else
    call go#list#Clean(l:listtype)
    call go#list#Window(l:listtype)

    if a:compile
      echon "vim-go: " | echohl Function | echon "[test] SUCCESS" | echohl None
    else
      echon "vim-go: " | echohl Function | echon "[test] PASS" | echohl None
    endif
  endif
  execute cd . fnameescape(dir)
endfunction

" Testfunc runs a single test that surrounds the current cursor position.
" Arguments are passed to the `go test` command.
function! go#test#Func(bang, ...) abort
  " search flags legend (used only)
  " 'b' search backward instead of forward
  " 'c' accept a match at the cursor position
  " 'n' do Not move the cursor
  " 'W' don't wrap around the end of the file
  "
  " for the full list
  " :help search
  let test = search('func \(Test\|Example\)', "bcnW")

  if test == 0
    echo "vim-go: [test] no test found immediate to cursor"
    return
  end

  let line = getline(test)
  let name = split(split(line, " ")[1], "(")[0]
  let args = [a:bang, 0, "-run", name . "$"]

  if a:0
    call extend(args, a:000)
  endif

  call call('go#cmd#Test', args)
endfunction

" test_compile is called when a GoTestCompile call is finished
function! s:test_compile(test_file, job, exit_status, data) abort
  call delete(a:test_file)
endfunction

" -----------------------
" | Neovim job handlers |
" -----------------------
let s:test_compile_handlers = {}

function! s:test_compile_handler(job, exit_status, data) abort
  if !has_key(s:test_compile_handlers, a:job.id)
    return
  endif
  let l:compile_file = s:test_compile_handlers[a:job.id]
  call delete(l:compile_file)
  unlet s:test_compile_handlers[a:job.id]
endfunction

function s:test_job(args) abort
  let status_dir = expand('%:p:h')
  let started_at = reltime()

  call go#statusline#Update(status_dir, {
        \ 'desc': "current status",
        \ 'type': a:args.cmd[1],
        \ 'state': "started",
        \})

  " autowrite is not enabled for jobs
  call go#cmd#autowrite()

  function! s:error_info_cb(job, exit_status, data) closure abort
    let status = {
          \ 'desc': 'last status',
          \ 'type': a:args.cmd[1],
          \ 'state': "success",
          \ }

    if a:exit_status
      let status.state = "failed"
    endif

    let elapsed_time = reltimestr(reltime(started_at))
    " strip whitespace
    let elapsed_time = substitute(elapsed_time, '^\s*\(.\{-}\)\s*$', '\1', '')
    let status.state .= printf(" (%ss)", elapsed_time)

    call go#statusline#Update(status_dir, status)
  endfunction

  let a:args.error_info_cb = funcref('s:error_info_cb')
  let callbacks = go#job#Spawn(a:args)

  let start_options = {
        \ 'callback': callbacks.callback,
        \ 'exit_cb': callbacks.exit_cb,
        \ }

  " modify GOPATH if needed
  let old_gopath = $GOPATH
  let $GOPATH = go#path#Detect()

  " pre start
  let dir = getcwd()
  let cd = exists('*haslocaldir') && haslocaldir() ? 'lcd ' : 'cd '
  let jobdir = fnameescape(expand("%:p:h"))
  execute cd . jobdir

  call job_start(a:args.cmd, start_options)

  " post start
  execute cd . fnameescape(dir)
  let $GOPATH = old_gopath
endfunction

" vim: sw=2 ts=2 et
"

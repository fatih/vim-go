" Spawn starts an asynchronous job. See the description of go#job#Options to
" understand the args parameter.
"
" Spawn returns a job.
function! go#job#Spawn(cmd, args)
  let l:options = go#job#Options(a:args)
  return go#job#Start(a:cmd, l:options)
endfunction

" Spawn starts an asynchronous job. See the description of go#job#Options to
" understand the args parameter.
"
" Spawn returns a job.
function! go#job#Spawn(cmd, args)
  let l:options = go#job#Options(a:args)
  return go#job#Start(a:cmd, l:options)
endfunction

" Options returns callbacks to be used with job_start. It is abstracted to be
" used with various go commands, such as build, test, install, etc.. This
" allows us to avoid writing the same callback over and over for some
" commands. It's fully customizable so each command can change it to its own
" logic.
"
" args is a dictionary with the these keys:
"   'cmd':
"     The value to pass to job_start().
"   'bang':
"     Set to 0 to jump to the first error in the error list.
"     Defaults to 0.
"   'statustype':
"     The status type to use when updating the status.
"     See statusline.vim.
"   'for':
"     The g:go_list_type_command key to use to get the error list type to use.
"     Defaults to '_job'
"   'errorformat':
"     The errorformat string to use when parsing errors. Defaults to
"     &errorformat.
"     See :help 'errorformat'.
"   'complete':
"     A function to call after the job exits and the channel is closed. The
"     function will be passed three arguments: the job, its exit code, and the
"     list of messages received from the channel. The default value will
"     process the messages and manage the error list after the job exits and
"     the channel is closed.

" The return value is a dictionary with these keys:
"   'callback':
"     A function suitable to be passed as a job callback handler. See
"     job-callback.
"   'exit_cb':
"     A function suitable to be passed as a job exit_cb handler. See
"     job-exit_cb.
"   'close_cb':
"     A function suitable to be passed as a job close_cb handler. See
"     job-close_cb.
"   'cwd':
"     The path to the directory which contains the current buffer.
function! go#job#Options(args)
  let cbs = {}
  let state = {
        \ 'winid': win_getid(winnr()),
        \ 'dir': getcwd(),
        \ 'jobdir': fnameescape(expand("%:p:h")),
        \ 'messages': [],
        \ 'bang': 0,
        \ 'for': "_job",
        \ 'exited': 0,
        \ 'exit_status': 0,
        \ 'closed': 0,
        \ 'errorformat': &errorformat,
        \ 'statustype' : ''
      \ }

  if has("patch-8.0.0902") || has('nvim')
    let cbs.cwd = state.jobdir
  endif

  if has_key(a:args, 'bang')
    let state.bang = a:args.bang
  endif

  if has_key(a:args, 'for')
    let state.for = a:args.for
  endif

  if has_key(a:args, 'statustype')
    let state.statustype = a:args.statustype
  endif

  if has_key(a:args, 'errorformat')
    let state.errorformat = a:args.errorformat
  endif

  " do nothing in state.complete by default.
  function state.complete(job, exit_status, data)
  endfunction

  function state.show_status(job, exit_status) dict
    if go#config#EchoCommandInfo()
      let prefix = ""
      if self.statustype != ''
        let prefix = '[' . self.statustype . '] '
      endif
      if a:exit_status == 0
        call go#util#EchoSuccess(prefix . "SUCCESS")
      else
        call go#util#EchoError(prefix . "FAIL")
      endif
    endif

    if self.statustype == ''
      return
    endif

    let status = {
          \ 'desc': 'last status',
          \ 'type': self.statustype,
          \ 'state': "success",
          \ }

    if a:exit_status
      let status.state = "failed"
    endif

    if has_key(self, 'started_at')
      let elapsed_time = reltimestr(reltime(self.started_at))
      " strip whitespace
      let elapsed_time = substitute(elapsed_time, '^\s*\(.\{-}\)\s*$', '\1', '')
      let status.state .= printf(" (%ss)", elapsed_time)
    endif

    call go#statusline#Update(self.jobdir, status)
  endfunction

  if has_key(a:args, 'complete')
    let state.complete = a:args.complete
  endif

  function! s:start(args) dict
    if self.statustype != ''
      let status = {
            \ 'desc': 'current status',
            \ 'type': self.statustype,
            \ 'state': "started",
            \ }

      call go#statusline#Update(self.jobdir, status)
    endif
    let self.started_at = reltime()
  endfunction
  " explicitly bind _start to state so that within it, self will
  " always refer to state. See :help Partial for more information.
  "
  " _start is intended only for internal use and should not be referenced
  " outside of this file.
  let cbs._start = function('s:start', [''], state)

  function! s:callback(chan, msg) dict
    call add(self.messages, a:msg)
  endfunction
  " explicitly bind callback to state so that within it, self will
  " always refer to state. See :help Partial for more information.
  let cbs.callback = function('s:callback', [], state)

  function! s:exit_cb(job, exitval) dict
    let self.exit_status = a:exitval
    let self.exited = 1

    call self.show_status(a:job, a:exitval)

    if self.closed
      call self.complete(a:job, self.exit_status, self.messages)
      call self.show_errors(a:job, self.exit_status, self.messages)
    endif
  endfunction
  " explicitly bind exit_cb to state so that within it, self will always refer
  " to state. See :help Partial for more information.
  let cbs.exit_cb = function('s:exit_cb', [], state)

  function! s:close_cb(ch) dict
    let self.closed = 1

    if self.exited
      let job = ch_getjob(a:ch)
      call self.complete(job, self.exit_status, self.messages)
      call self.show_errors(job, self.exit_status, self.messages)
    endif
  endfunction
  " explicitly bind close_cb to state so that within it, self will
  " always refer to state. See :help Partial for more information.
  let cbs.close_cb = function('s:close_cb', [], state)

  function state.show_errors(job, exit_status, data)
    let l:winid = win_getid(winnr())
    call win_gotoid(self.winid)

    let l:listtype = go#list#Type(self.for)
    if a:exit_status == 0
      call go#list#Clean(l:listtype)
      call win_gotoid(l:winid)
      return
    endif

    let l:listtype = go#list#Type(self.for)
    if len(a:data) == 0
      call go#list#Clean(l:listtype)
      call win_gotoid(l:winid)
      return
    endif

    let out = join(self.messages, "\n")

    let l:cd = exists('*haslocaldir') && haslocaldir() ? 'lcd' : 'cd'
    try
      " parse the errors relative to self.jobdir
      execute l:cd self.jobdir
      call go#list#ParseFormat(l:listtype, self.errorformat, out, self.for)
      let errors = go#list#Get(l:listtype)
    finally
      execute l:cd fnameescape(self.dir)
    endtry


    if empty(errors)
      " failed to parse errors, output the original content
      call go#util#EchoError(self.messages + [self.dir])
      call win_gotoid(l:winid)
      return
    endif

    if self.winid == l:winid
      call go#list#Window(l:listtype, len(errors))
      if !self.bang
        call go#list#JumpToFirst(l:listtype)
      endif
    endif
  endfunction

  return cbs
endfunction

function! go#job#Start(cmd, options)
  let l:cd = exists('*haslocaldir') && haslocaldir() ? 'lcd' : 'cd'
  let l:options = copy(a:options)

  if !has_key(l:options, 'cwd')
    " pre start
    let dir = getcwd()
    execute l:cd fnameescape(expand("%:p:h"))
  endif

  if has_key(l:options, '_start')
    call l:options._start()
    " remove _start to play nicely with vim (when vim encounters an unexpected
    " job option it reports an "E475: invalid argument" error.
    unlet l:options._start
  endif

  let job = job_start(a:cmd, l:options)

  if !has_key(l:options, 'cwd')
    " post start
    execute l:cd fnameescape(dir)
  endif

  return job
endfunction

" vim: sw=2 ts=2 et

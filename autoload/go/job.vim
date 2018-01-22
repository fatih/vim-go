" Spawn returns callbacks to be used with job_start. It is abstracted to be
" used with various go commands, such as build, test, install, etc.. This
" allows us to avoid writing the same callback over and over for some
" commands. It's fully customizable so each command can change it to it's own
" logic.
"
" args is a dictionary with the these keys:
"   'cmd':
"     The value to pass to job_start().
"   'bang':
"     Set to 0 to jump to the first error in the error list.
"     Defaults to 0.
"   'for':
"     The g:go_list_type_command key to use to get the error list type to use.
"     Defaults to '_job'
"   'complete':
"     A function to call after the job exits and the channel is closed. The
"     function will be passed three arguments: the job, its exit code, and the
"     list of messages received from the channel. The default value will
"     process the messages and manage the error list after the job exits and
"     the channel is closed.
"   'callback':
"     A function to call when there is a message to read from the job's
"     channel. The function will be passed two arguments: the channel and a
"     message. See job-callback.

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
"   'winnr':
"     The number of the current window.
"   'dir':
"     The current working directory.
"   'jobdir':
"     The directory of the current buffer.fnameescape(expand("%:p:h")),
"   'messages':
"     The list of messages received from the channel and filtered by args.
"   'args':
"     A dictionary with a single key, 'cmd', whose value is the a:args.cmd,
"   'bang':
"     Set to 0 when the first error will be jumped to after reading and
"     processing all messages from the channel.
"   'for':
"     The g:go_list_type_command key to use to get the error list type to use.
"   'complete':
"     A function that will be called after the job exits and the channel is
"     closed. It will process all the read messages and manage the error list
"     and window.

function go#job#Spawn(args)
  let cbs = {
        \ 'winnr': winnr(),
        \ 'dir': getcwd(),
        \ 'jobdir': fnameescape(expand("%:p:h")),
        \ 'messages': [],
        \ 'args': a:args.cmd,
        \ 'bang': 0,
        \ 'for': "_job",
        \ }

  if has_key(a:args, 'bang')
    let cbs.bang = a:args.bang
  endif

  if has_key(a:args, 'for')
    let cbs.for = a:args.for
  endif

  let l:exited = 0
  let l:exit_status = 0
  let l:closed = 0

  function cbs.callback(chan, msg) dict
    call add(self.messages, a:msg)
  endfunction

  " override callback handler if user provided it
  if has_key(a:args, 'callback')
    let cbs.callback = a:args.callback
  endif

  function cbs.exit_cb(job, exitval) dict closure
    let exit_status = a:exitval
    let exited = 1

    if get(g:, 'go_echo_command_info', 1)
      if a:exitval == 0
        call go#util#EchoSuccess("SUCCESS")
      else
        call go#util#EchoError("FAILED")
      endif
    endif

    if closed
      if has_key(self, 'complete')
        call self.complete(a:job, l:exit_status, self.messages)
      endif
      call self.show_errors(a:job, exit_status, self.messages)
    endif
  endfunction

  function cbs.close_cb(ch) dict closure
    let closed = 1

    if exited
      if has_key(self, 'complete')
        call self.complete(a:job, l:exit_status, self.messages)
      endif
      call self.show_errors(ch_getjob(a:ch), exit_status, self.messages)
    endif
  endfunction

  function cbs.show_errors(job, exit_status, data) dict closure
    let l:listtype = go#list#Type(self.for)
    if a:exit_status == 0
      call go#list#Clean(l:listtype)
      call go#list#Window(l:listtype)
      return
    endif

    let l:listtype = go#list#Type(self.for)
    if len(self.messages) == 0
      call go#list#Clean(l:listtype)
      call go#list#Window(l:listtype)
      return
    endif

    let cd = exists('*haslocaldir') && haslocaldir() ? 'lcd ' : 'cd '
    try
      execute cd self.jobdir
      let errors = go#tool#ParseErrors(self.messages)
      let errors = go#tool#FilterValids(errors)
    finally
      execute cd . fnameescape(self.dir)
    endtry

    if empty(errors)
      " failed to parse errors, output the original content
      call go#util#EchoError(self.messages + [self.dir])
      return
    endif

    if self.winnr == winnr()
      call go#list#Populate(l:listtype, errors, join(self.args))
      call go#list#Window(l:listtype, len(errors))
      if !self.bang
        call go#list#JumpToFirst(l:listtype)
      endif
    endif
  endfunction

  " override callback handler if user provided it
  if has_key(a:args, 'complete')
    let cbs.complete = a:args.complete
  endif

  " override close_cb callback handler if user provided it
  if has_key(a:args, 'close_cb')
    " TODO(bc): wrap a.args.close_cb to make sure closed gets set.
    let cbs.close_cb = a:args.close_cb
  endif

  " override exit callback handler if user provided it
  if has_key(a:args, 'exit_cb')
    " TODO(bc): wrap a.args.exit_cb to make sure exited and exit_status gets
    " set.
    let cbs.exit_cb = a:args.exit_cb
  endif

  return cbs
endfunction

" vim: sw=2 ts=2 et

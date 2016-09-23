" Spawn returns callbacks to be used with job_start.  It's abstracted to be
" used with various go command, such as build, test, install, etc.. This avoid
" us to write the same callback over and over for some commands. It's fully
" customizable so each command can change it to it's own logic.
function go#job#Spawn(args)
  let cbs = {
        \ 'winnr': winnr(),
        \ 'dir': getcwd(),
        \ 'jobdir': fnameescape(expand("%:p:h")),
        \ 'messages': [],
        \ }

  if has_key(a:args, 'bang')
    let cbs.bang = a:args.bang
  endif

  " add final callback to be called if async job is finished
  " The signature should be in form: func(job, exit_status, messages)
  if has_key(a:args, 'custom_cb')
    let cbs.custom_cb = a:args.custom_cb
  endif

  function cbs.callback(chan, msg) dict
    call add(self.messages, a:msg)
  endfunction

  function cbs.close_cb(chan) dict
    let l:job = ch_getjob(a:chan)
    let l:info = job_info(l:job)

    if has_key(self, 'custom_cb')
      call self.custom_cb(l:job, l:info.exitval, self.messages)
    endif

    if l:info.exitval == 0
      call go#list#Clean(0)
      call go#list#Window(0)
      call go#util#EchoSuccess("SUCCESS")
      return
    endif

    call self.show_errors()
  endfunction

  function cbs.show_errors() dict
    call go#util#EchoError("FAILED")

    let cd = exists('*haslocaldir') && haslocaldir() ? 'lcd ' : 'cd '
    try
      execute cd self.jobdir
      let errors = go#tool#ParseErrors(self.messages)
      let errors = go#tool#FilterValids(errors)
    finally
      execute cd . fnameescape(self.dir)
    endtry

    if !len(errors)
      " failed to parse errors, output the original content
      call go#util#EchoError(join(self.messages, " "))
      call go#util#EchoError(self.dir)
      return
    endif

    if self.winnr == winnr()
      let l:listtype = "quickfix"
      call go#list#Populate(l:listtype, errors)
      call go#list#Window(l:listtype, len(errors))
      if !empty(errors) && !self.bang
        call go#list#JumpToFirst(l:listtype)
      endif
    endif
  endfunction

  " override callback handler if user provided it
  if has_key(a:args, 'callback')
    let cbs.callback = a:args.callback
  endif

  " override close callback handler if user provided it
  if has_key(a:args, 'close_cb')
    let cbs.close_cb = a:args.close_cb
  endif

  return cbs
endfunction

function! go#job#Buffer(bang, args)
  " autowrite is not enabled for jobs
  call go#cmd#autowrite()

  " modify GOPATH if needed
  let old_gopath = $GOPATH
  let $GOPATH = go#path#Detect()

  " execute go build in the files directory
  let cd = exists('*haslocaldir') && haslocaldir() ? 'lcd ' : 'cd '
  let dir = getcwd()
  let jobdir = fnameescape(expand("%:p:h"))
  execute cd . jobdir

  let opts = {
        \ 'dir': dir,
        \ 'bang': a:bang, 
        \ 'winnr': winnr(),
        \ 'errs' : [],
        \ 'bufnr' : s:create_new_buffer(),
        \ }

  func opts.errorHandler(chan, msg) dict
    " contains stderr
    call add(self.errs, a:msg)
  endfunc

  func opts.closeHandler(chan) dict
    call s:stop_job()
  endfunc

  func opts.exitHandler(job, exit_status) dict
    if a:exit_status == 0
      call go#list#Clean(0)
      call go#list#Window(0)
      call go#util#EchoSuccess("SUCCESS")
      return
    endif

    if bufloaded(self.bufnr)
      sil exe 'bdelete! '.self.bufnr
    endif

    if empty(self.errs) 
      return
    endif

    call s:show_errors(self.bang, self.errs, self.dir, self.winnr)
  endfunc

  " stop previous job before we continue
  if exists('s:job_buffer')
    call job_stop(s:job_buffer)
    let status = job_status(s:job_buffer)
    echo status
    unlet s:job_buffer
  endif

  let s:job_buffer = job_start(a:args.cmd, {
        \	"out_io": "buffer",
        \	"out_buf": opts.bufnr,
        \	"exit_cb": opts.exitHandler,
        \	"err_cb": opts.errorHandler,
        \	"close_cb": opts.closeHandler,
        \ })

  call job_status(s:job_buffer)
  execute cd . fnameescape(dir)

  autocmd BufWinLeave <buffer> call s:stop_job()

  " restore back GOPATH
  let $GOPATH = old_gopath
endfunction

func s:stop_job()
  if !exists('s:job_buffer')
    return
  endif

  if exists("#BufWinLeave#<buffer>") 
    autocmd! BufWinLeave <buffer>
  endif

  call job_status(s:job_buffer) "trigger exitHandler
  call job_stop(s:job_buffer)
  unlet s:job_buffer
endfunc

function! s:show_errors(bang, errs, dir, winnr)
  call go#util#EchoError("FAILED")

  let cd = exists('*haslocaldir') && haslocaldir() ? 'lcd ' : 'cd '
  let dir = getcwd()
  try
    execute cd a:dir
    let errors = go#tool#ParseErrors(a:errs)
    let errors = go#tool#FilterValids(errors)
  finally
    execute cd . fnameescape(dir)
  endtry

  if !len(errors)
    " failed to parse errors, output the original content
    call go#util#EchoError(a:errs[0])
    return
  endif

  if a:winnr == winnr()
    let l:listtype = "quickfix"
    call go#list#Populate(l:listtype, errors)
    call go#list#Window(l:listtype, len(errors))
    if !empty(errors) && !a:bang
      call go#list#JumpToFirst(l:listtype)
    endif
  endif
endfunction

function! s:create_new_buffer()
  execute 'new __go_job__'
  let l:buf_nr = bufnr('%')

  " cap buffer height to 10
  let max_height = 10
  exe 'resize ' . max_height

  setlocal filetype=gojob
  setlocal bufhidden=delete
  setlocal buftype=nofile
  setlocal winfixheight
  setlocal noswapfile
  setlocal nobuflisted
  setlocal nocursorline
  setlocal nocursorcolumn

  " close easily with <esc> or enter
  noremap <buffer> <silent> <CR> :<C-U>close<CR>
  noremap <buffer> <silent> <Esc> :<C-U>close<CR>

  return l:buf_nr
endfunction

" vim: sw=2 ts=2 et

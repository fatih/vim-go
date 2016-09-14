function! go#job#Spawn(bang, args)
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
        \ 'combined' : [],
        \ }

  " add external callback to be called if async job is finished
  if has_key(a:args, 'external_cb')
    let opts.external_cb = a:args.external_cb
  endif

  func opts.callbackHandler(chan, msg) dict
    " contains both stderr and stdout
    call add(self.combined, a:msg)
  endfunc

  func opts.closeHandler(chan) dict
    if !exists('s:job')
      return
    endif

    call job_status(s:job) "trigger exitHandler
    call job_stop(s:job)
    unlet s:job
  endfunc

  func opts.exitHandler(job, exit_status) dict
    if has_key(self, 'external_cb')
      call self.external_cb(a:job, a:exit_status, self.combined)
    endif

    if a:exit_status == 0
      call go#list#Clean(0)
      call go#list#Window(0)
      call go#util#EchoSuccess("SUCCESS")
      return
    endif

    call s:show_errors(self.bang, self.combined, self.dir, self.winnr)
  endfunc

  let l:start_args = {
        \	"callback": opts.callbackHandler,
        \	"exit_cb": opts.exitHandler,
        \	"close_cb": opts.closeHandler,
        \ }

  " Emulate the 'input' arg to the system() call:
  " When {input} is given and is a string this string is written 
  " to a file and passed as stdin to the command.  The string is 
  " written as-is, you need to take care of using the correct line 
  " separators yourself.
  if has_key(a:args, 'input')
    let l:tmpname = tempname()
    call writefile(split(a:args.input, "\n"), l:tmpname, "b")
    let l:start_args.in_io = "file"
    let l:start_args.in_name = l:tmpname
  endif

  let s:job = job_start(a:args.cmd, l:start_args)

  call job_status(s:job)
  execute cd . fnameescape(dir)

  " restore back GOPATH
  let $GOPATH = old_gopath
endfunction

function! go#job#SpawnContinous(bang, args)
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
        \ 'combined' : [],
        \ }

  " add external callback to be called if async job is finished
  if has_key(a:args, 'external_cb')
    let opts.external_cb = a:args.external_cb
  endif

  func opts.callbackHandler(chan, msg) dict
    " contains both stderr and stdout
    let errformat = "%f:%l:%c:%t%*[^:]:\ %m,%f:%l::%t%*[^:]:\ %m"

    " backup users errorformat, will be restored once we are finished
    let old_errorformat = &errorformat
    " parse and populate the location list
    let &errorformat = errformat

    caddexpr a:msg

    let &errorformat = old_errorformat

    " call add(self.combined, a:msg)
  endfunc

  func opts.closeHandler(chan) dict
    if !exists('s:job')
      return
    endif

    call job_status(s:job) "trigger exitHandler
    call job_stop(s:job)
    unlet s:job
  endfunc

  func opts.exitHandler(job, exit_status) dict
    if has_key(self, 'external_cb')
      call self.external_cb(a:job, a:exit_status, self.combined)
    endif

    cbottom
    if a:exit_status == 0
      call go#list#Clean(0)
      call go#list#Window(0)
      call go#util#EchoSuccess("SUCCESS")
      return
    endif

    " call s:show_errors(self.bang, self.combined, self.dir, self.winnr)
  endfunc

  let l:start_args = {
        \	"callback": opts.callbackHandler,
        \	"exit_cb": opts.exitHandler,
        \	"close_cb": opts.closeHandler,
        \ }

  " Emulate the 'input' arg to the system() call:
  " When {input} is given and is a string this string is written 
  " to a file and passed as stdin to the command.  The string is 
  " written as-is, you need to take care of using the correct line 
  " separators yourself.
  if has_key(a:args, 'input')
    let l:tmpname = tempname()
    call writefile(split(a:args.input, "\n"), l:tmpname, "b")
    let l:start_args.in_io = "file"
    let l:start_args.in_name = l:tmpname
  endif

  let s:job = job_start(a:args.cmd, l:start_args)

  copen
  call setqflist([], 'r', {'title': 'GoMetaLinter'})
  call job_status(s:job)
  execute cd . fnameescape(dir)

  " restore back GOPATH
  let $GOPATH = old_gopath
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

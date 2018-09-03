" s:jobs is a global reference to all jobs started with new()
let s:jobs = {}"

" new creates a new terminal with the given command. Mode is set based on the
" global variable g:go_term_mode, which is by default set to :vsplit
function! go#term#new(bang, cmd) abort
  return go#term#newmode(a:bang, a:cmd, go#config#TermMode())
endfunction

function! s:term_add_output(list, msg)
  let out = substitute(a:msg, "\x1b\\[[^a-z]\\+[a-z]", '', 'g')
  let out = substitute(out, '[\r\n]$', '', 'g')
  if !empty(out)
    for l in split(out, "\n")
      call add(a:list, l)
    endfor
  endif
endfunction

function! s:term_vim8(bang, cmd, mode) abort
  " modify GOPATH if needed
  let old_gopath = $GOPATH
  let $GOPATH = go#path#Detect()

  " execute go build in the files directory
  let l:winnr = winnr()
  let cd = exists('*haslocaldir') && haslocaldir() ? 'lcd ' : 'cd '
  let dir = getcwd()

  execute cd . fnameescape(expand("%:p:h"))

  let ctx = {
        \ 'cmd' : a:cmd,
        \ 'bang' : a:bang,
        \ 'winid' : win_getid(winnr()),
        \ 'termwinid' : 0,
        \ 'stderr' : [],
        \ 'stdout' : [],
        \ }

  let buf = term_start(a:cmd, {
  \ 'term_name': '__go_term__',
  \ 'out_cb': {job, msg->[execute('call s:term_add_output(ctx.stdout, msg)'), ctx]},
  \ 'err_cb': {job, msg->[execute('call s:term_add_output(ctx.stderr, msg)'), ctx]},
  \ 'exit_cb':  {job, st->[s:on_exit(ctx, buf, st), buf]},
  \})
  let ctx.termwinid = win_getid(winnr())

  execute cd . fnameescape(dir)

  " resize new term if needed.
  let height = go#config#TermHeight()
  let width = go#config#TermWidth()

  " we also need to resize the pty, so there you go...
  call term_setsize(buf, width, height)

  call win_gotoid(ctx.winid)


  let s:jobs[buf] = ctx
  return buf
endfunction

function! s:term_nvim(bang, cmd, mode) abort
  let mode = a:mode
  if empty(mode)
    let mode = go#config#TermMode()
  endif

  let state = {
        \ 'cmd': a:cmd,
        \ 'bang' : a:bang,
        \ 'winid': win_getid(winnr()),
        \ 'stdout': []
        \ 'stderr': []
      \ }

  " execute go build in the files directory
  let cd = exists('*haslocaldir') && haslocaldir() ? 'lcd ' : 'cd '
  let dir = getcwd()

  execute cd . fnameescape(expand("%:p:h"))

  execute mode.' __go_term__'

  setlocal filetype=goterm
  setlocal bufhidden=delete
  setlocal winfixheight
  setlocal noswapfile
  setlocal nobuflisted

  " explicitly bind callbacks to state so that within them, self will always
  " refer to state. See :help Partial for more information.
  "
  " Don't set an on_stderr, because it will be passed the same data as
  " on_stdout. See https://github.com/neovim/neovim/issues/2836
  let job = {
        \ 'on_stdout': function('s:on_stdout_nvim', [], state),
        \ 'on_stderr': function('s:on_stderr_nvim', [], state),
        \ 'on_exit' : function('s:on_exit', [], state),
      \ }

  let state.id = termopen(a:cmd, job)
  let state.termwinid = win_getid(winnr())

  execute cd . fnameescape(dir)

  " resize new term if needed.
  let height = go#config#TermHeight()
  let width = go#config#TermWidth()

  " Adjust the window width or height depending on whether it's a vertical or
  " horizontal split.
  if mode =~ "vertical" || mode =~ "vsplit" || mode =~ "vnew"
    exe 'vertical resize ' . width
  elseif mode =~ "split" || mode =~ "new"
    exe 'resize ' . height
  endif

  " we also need to resize the pty, so there you go...
  call jobresize(state.id, width, height)

  call win_gotoid(state.winid)

  return state.id
endfunction

" new creates a new terminal with the given command and window mode.
function! go#term#newmode(bang, cmd, mode) abort

  let mode = a:mode
  if empty(mode)
    let mode = go#config#TermMode()
  endif

  if has('nvim')
    return s:term_nvim(a:bang, a:cmd, a:mode)
  else
    return s:term_vim8(a:bang, a:cmd, a:mode)
  endif
endfunction

function! s:on_stdout_nvim(job_id, data, event) dict abort
  if !has_key(s:jobs, a:job_id)
    return
  endif
  let job = s:jobs[a:job_id]

  call extend(job.stdout, a:data)
endfunction

function! s:on_stderr_nvim(job_id, data, event) dict abort
  if !has_key(s:jobs, a:job_id)
    return
  endif
  let job = s:jobs[a:job_id]

  call extend(job.stderr, a:data)
endfunction

function! s:on_exit_nvim(job_id, exit_status, event) dict abort
  return s:on_exit(self, a:job_id, a:exit_status)
endfunction

function! s:on_exit(self, job_id, exit_status) abort
  let l:listtype = go#list#Type("_term")

  " usually there is always output so never branch into this clause
  if empty(a:self.stdout)
    call s:cleanlist(a:self.winid, l:listtype)
    return
  endif

  let errors = go#tool#ParseErrors(a:self.stdout)
  let errors = go#tool#FilterValids(errors)

  if !empty(errors)
    " close terminal; we don't need it anymore
    call win_gotoid(a:self.termwinid)
    close

    call win_gotoid(a:self.winid)

    let title = a:self.cmd
    if type(title) == v:t_list
      let title = join(a:self.cmd)
    endif
    call go#list#Populate(l:listtype, errors, title)
    call go#list#Window(l:listtype, len(errors))
    if !a:self.bang
      call go#list#JumpToFirst(l:listtype)
    endif

    return
  endif

  call s:cleanlist(a:self.winid, l:listtype)
endfunction

function! s:cleanlist(winid, listtype) abort
  " There are no errors. Clean and close the list. Jump to the window to which
  " the location list is attached, close the list, and then jump back to the
  " current window.
  let winid = win_getid(winnr())
  call win_gotoid(a:winid)
  call go#list#Clean(a:listtype)
  call win_gotoid(l:winid)
endfunction

" vim: sw=2 ts=2 et

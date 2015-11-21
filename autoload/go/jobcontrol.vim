let s:jobs = {}

function! go#jobcontrol#Spawn(args)
  let job = s:spawn(a:args[0], a:args)
  return job.id
endfunction

function! s:spawn(name, args)
  let job = { 
        \ 'name': a:name, 
        \ 'stderr' : [],
        \ 'stdout' : [],
        \ 'on_stdout': function('s:on_stdout'),
        \ 'on_stderr': function('s:on_stderr'),
        \ 'on_exit' : function('s:on_exit'),
        \ }

  " abort previous running jobs
  " call self.abort(a:name)

  " modify GOPATH if needed
  let old_gopath = $GOPATH
  let $GOPATH = go#path#Detect()

  " execute go build in the files directory
  let cd = exists('*haslocaldir') && haslocaldir() ? 'lcd ' : 'cd '
  let dir = getcwd()
  try
    execute cd . fnameescape(expand("%:p:h"))

    " append the subcommand, such as 'build'
    let argv = ['go'] + a:args
    " call extend(argv, a:args) 

    " run, forrest, run!
    let id = jobstart(argv, job)
    let job.id = id
    let s:jobs[id] = job
  finally
    execute cd . fnameescape(dir)
  endtry

  " restore back GOPATH
  let $GOPATH = old_gopath
  return job
endfunction

function! s:on_stdout(job_id, data)
  if !has_key(s:jobs, a:job_id)
    return
  endif
  let job = s:jobs[a:job_id]

  call extend(job.stdout, a:data)
endfunction

function! s:on_stderr(job_id, data)
  if !has_key(s:jobs, a:job_id)
    return
  endif
  let job = s:jobs[a:job_id]

  call extend(job.stderr, a:data)
endfunction

function! s:on_exit(job_id, data)
  if !has_key(s:jobs, a:job_id)
    return
  endif
  let job = s:jobs[a:job_id]

  if empty(job.stderr)
    call setqflist([])
    call go#util#Cwindow()
    redraws! | echon "vim-go: " | echohl Function | echon printf("[%s] SUCCESS", self.name) | echohl None
    return
  else
    redraws! | echon "vim-go: " | echohl ErrorMsg | echon printf("[%s] FAILED", self.name)| echohl None
    call go#tool#ShowErrors(join(job.stderr, "\n"))
    let errors = getqflist()
    call go#util#Cwindow(len(errors))
    if !empty(errors)
      cc 1 "jump to first error if there is any
    endif
  endif

  " do not keep anything when we are finished
  unlet s:jobs[a:job_id]
endfunction

function! s:abort_all()
  if empty(s:jobs)
    return
  endif

  for id in keys(s:jobs)
    if id > 0
      silent! call jobstop(id)
    endif
  endfor

  let s:jobs = {}
endfunction

function! s:abort(name)
  if empty(s:jobs)
    return
  endif

  for job in values(s:jobs)
    if job.name == name && job.id > 0
      silent! call jobstop(job.id)
      unlet s:jobs['job.id']
      redraws! | echon "vim-go: " | echohl WarningMsg | echon printf("[%s] ABORTED", a:name) | echohl None

    endif
  endfor
endfunction

" vim:ts=2:sw=2:et

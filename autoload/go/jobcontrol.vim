" s:jobs is a global reference to all jobs started with Spawn() or with the
" internal function s:spawn
let s:jobs = {}

" Spawn is a wrapper around s:spawn. It can be executed by other files and
" scripts if needed. Desc defines the description for printing the status
" during the job execution (useful for statusline integration).
function! go#jobcontrol#Spawn(desc, args)
  " autowrite is not enabled for jobs
  call go#cmd#autowrite()

  let job = s:spawn(a:desc, a:args[0], a:args)
  return job.id
endfunction

function! go#jobcontrol#DisplayLoclist()
  if empty(s:jobs)
    return ''
  endif

  for job in values(s:jobs)
    if job.winnr == winnr() && !empty(job.stderr)
      let errors = go#tool#ParseErrors(job.stderr)
      call go#list#PopulateWin(job.winnr, errors)
      call go#list#Window(len(errors))

      unlet s:jobs[job.id]
      return
    endif
  endfor
endfunction

" Statusline returns the current status of the job
function! go#jobcontrol#Statusline() abort
  if empty(s:jobs)
    return ''
  endif

  for job in values(s:jobs)
    if job.filename == fnameescape(expand("%:p"))
      return job.desc
    endif
  endfor

  return ''
endfunction

" spawn spawns a go subcommand with the name and arguments with jobstart. Once
" a job is started a reference will be stored inside s:jobs. spawn changes the
" GOPATH when g:go_autodetect_gopath is enabled. The job is started inside the
" current files folder.
function! s:spawn(desc, name, args)
  let job = { 
        \ 'name': a:name, 
        \ 'desc': a:desc, 
        \ 'id': '',
        \ 'winnr': winnr(),
        \ 'stderr' : [],
        \ 'stdout' : [],
        \ 'on_stdout': function('s:on_stdout'),
        \ 'on_stderr': function('s:on_stderr'),
        \ 'on_exit' : function('s:on_exit'),
        \ }

  " modify GOPATH if needed
  let old_gopath = $GOPATH
  let $GOPATH = go#path#Detect()

  " execute go build in the files directory
  let cd = exists('*haslocaldir') && haslocaldir() ? 'lcd ' : 'cd '
  let job.filename = fnameescape(expand("%:p"))
  let dir = getcwd()

  execute cd . fnameescape(expand("%:p:h"))

  " append the subcommand, such as 'build'
  let argv = ['go'] + a:args

  " run, forrest, run!
  let id = jobstart(argv, job)
  let job.id = id
  let s:jobs[id] = job

  execute cd . fnameescape(dir)

  " restore back GOPATH
  let $GOPATH = old_gopath
  return job
endfunction

" on_exit is the exit handler for jobstart(). It handles cleaning up the job
" references and also displaying errors in the quickfix window collected by
" on_stderr handler. If there are no errors and a quickfix window is open,
" it'll be closed.
function! s:on_exit(job_id, data)
  if empty(self.stderr)
    call go#list#Clean()
    call go#list#Window()
    call go#util#EchoSuccess(printf("[%s] SUCCESS", self.name))

    " do not keep anything when we are finished
    unlet s:jobs[a:job_id]
    return
  endif


  " if we are still in the same windows show the list
  if self.winnr == winnr()
    let errors = go#tool#ParseErrors(self.stderr)
    call go#list#PopulateWin(self.winnr, errors)
    call go#list#Window(len(errors))

    if has_key(s:jobs, a:job_id) 
      unlet s:jobs[a:job_id]
    endif

    call go#util#EchoError(printf("[%s] FAILED", self.name))
  endif
endfunction

" on_stdout is the stdout handler for jobstart(). It collects the output of
" stderr and stores them to the jobs internal stdout list. 
function! s:on_stdout(job_id, data)
  call extend(self.stdout, a:data)
endfunction

" on_stderr is the stderr handler for jobstart(). It collects the output of
" stderr and stores them to the jobs internal stderr list.
function! s:on_stderr(job_id, data)
  call extend(self.stderr, a:data)
endfunction

" abort_all aborts all current jobs created with s:spawn()
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

" abort aborts the job with the given name, where name is the first argument
" passed to s:spawn()
function! s:abort(name)
  if empty(s:jobs)
    return
  endif

  for job in values(s:jobs)
    if job.name == name && job.id > 0
      silent! call jobstop(job.id)
      unlet s:jobs['job.id']
      call go#util#EchoWarning(printf("[%s] ABORTED", a:name))
    endif
  endfor
endfunction

" vim:ts=2:sw=2:et

" s:jobs is a global reference to all jobs started with new()
let s:jobs = {}

" new creates a new terminal with the given command
function! go#term#new(cmd, mode)
	execute a:mode.' new'
  call s:init_view()

  let job = { 
        \ 'on_stdout': function('s:on_stdout'),
        \ 'on_stderr': function('s:on_stderr'),
        \ 'on_exit' : function('s:on_exit'),
        \ }

  let id = termopen(a:cmd, job)
	let job.id = id
  let s:jobs[id] = job
	startinsert
	return id
endfunction

"init_view initializes the view for a new terminal buffer
function! s:init_view()
  sil file `="[term]"`
	setlocal bufhidden=delete
	setlocal buftype=nofile
	setlocal winfixheight
	setlocal noswapfile
	setlocal nobuflisted
	setlocal cursorline		" make it easy to distinguish
endfunction

function! s:on_stdout(job_id, data)
endfunction

function! s:on_stderr(job_id, data)
endfunction

function! s:on_exit(job_id, data)
  unlet s:jobs[a:job_id]
endfunction

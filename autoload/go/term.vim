if has('nvim') && !exists("g:go_term_mode")
    let g:go_term_mode = 'vsplit'
endif

" s:jobs is a global reference to all jobs started with new()
let s:jobs = {}

" new creates a new terminal with the given command. Mode is set based on the
" global variable g:go_term_mode, which is by default set to :vsplit
function! go#term#new(cmd)
	call go#term#newmode(a:cmd, g:go_term_mode)
endfunction

" new creates a new terminal with the given command and window mode.
function! go#term#newmode(cmd, mode)
	let mode = a:mode
	if empty(mode)
		let mode = g:go_term_mode
	endif

	execute mode.' new'

  sil file `="[term]"`
	setlocal bufhidden=delete
	setlocal buftype=nofile
	setlocal winfixheight
	setlocal noswapfile
	setlocal nobuflisted
	setlocal cursorline		" make it easy to distinguish

  let job = { 
        \ 'on_stdout': function('s:on_stdout'),
        \ 'on_stderr': function('s:on_stderr'),
        \ 'on_exit' : function('s:on_exit'),
        \ }

  let id = termopen(a:cmd, job)
	let job.id = id
	startinsert

	" resize new term if needed.
	let height = get(g:, 'go_term_height', winheight(0))
	let width = get(g:, 'go_term_width', winwidth(0))

	" we are careful how to resize. for example it's vertical we don't change
	" the height. The below command resizes the buffer
	if a:mode == "split"
		exe 'resize ' . height
	elseif a:mode == "vertical"
		exe 'vertical resize ' . width
	endif

	" we also need to resize the pty, so there you go...
	call jobresize(id, width, height)

  let s:jobs[id] = job
	return id
endfunction

function! s:on_stdout(job_id, data)
endfunction

function! s:on_stderr(job_id, data)
endfunction

function! s:on_exit(job_id, data)
  unlet s:jobs[a:job_id]
endfunction

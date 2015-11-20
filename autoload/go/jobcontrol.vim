let GoCommandJob = {}

function GoCommandJob.on_stdout(job_id, data)
	call extend(self.stdout, a:data)
endfunction

function GoCommandJob.on_stderr(job_id, data)
	call extend(self.stderr, a:data)
endfunction

function GoCommandJob.on_exit(job_id, data)
	call self.update_quickfix()
	call self.show_quickfix()
endfunction

function GoCommandJob.show_quickfix()
	let errors = getqflist()
	call go#util#Cwindow(len(errors))
	if !empty(errors)
		cc 1 "jump to first error if there is any
    else
        redraws! | echon "vim-go: " | echohl Function | echon printf("[%s] SUCCESS", self.name) | echohl None
	endif
endfunction

function GoCommandJob.update_quickfix()
    if empty(self.stderr)
        call setqflist([])
        call go#util#Cwindow()
    else
        redraws! | echon "vim-go: " | echohl ErrorMsg | echon printf("[%s] FAILED", self.name)| echohl None
	    call go#tool#ShowErrors(join(self.stderr, "\n"))
    endif
endfunction

function GoCommandJob.cmd(args)
	let argv = ['go']
	call extend(argv, a:args) " append the subcommand, such as 'build'

	" each Go instance has these local fields.
	" name: defines the subcommand
	" stderr: stores the stderr
	" stdout: stores the stdout
	let fields = {
				\ 'name': a:args[0],  
				\ 'stderr':[], 
				\ 'stdout':[]
				\ }

	" populate the instace with on_stdout, on_stderr ... functions. These are
	" needed by jobstart.
	let instance = extend(copy(g:GoCommandJob), fields)

	" modify GOPATH if needed
	let old_gopath = $GOPATH
	let $GOPATH = go#path#Detect()

	" execute go build in the files directory
	let cd = exists('*haslocaldir') && haslocaldir() ? 'lcd ' : 'cd '
	let dir = getcwd()
	try
		execute cd . fnameescape(expand("%:p:h"))
		" run, forrest, run!
		let instance.id = jobstart(argv, instance)
	finally
		execute cd . fnameescape(dir)
	endtry

	" restore back GOPATH
	let $GOPATH = old_gopath

	return instance
endfunction

function! go#jobcontrol#Run(args)
	let job1 = g:GoCommandJob.cmd(a:args)
	return job1.id
endfunction


" vim:ts=4:sw=4:et

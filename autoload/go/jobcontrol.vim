let Go = {}

function Go.on_stdout(job_id, data)
	call extend(self.stdout, a:data)
endfunction

function Go.on_stderr(job_id, data)
	call extend(self.stderr, a:data)
endfunction

function Go.on_exit(job_id, data)
	call self.set_quickfix()
	call self.show_quickfix()
endfunction

function Go.show_quickfix()
	let errors = getqflist()
	call go#util#Cwindow(len(errors))
	if !empty(errors)
		cc 1 "jump to first error if there is any
	endif
endfunction

function Go.set_quickfix()
	call go#tool#ShowErrors(join(self.stderr, "\n"))
endfunction

function Go.cmd(...)
	let argv = ['go']
	if a:0 > 0
		call extend(argv, a:000) " append the subcommand, such as 'build'
	else
		redraws! | echon "vim-go: " | echohl ErrorMsg | echon "subcommand not passed"| echohl None
		return -1
	endif

	" each Go instance has these local fields.
	" name: defines the subcommand
	" stderr: stores the stderr
	" stdout: stores the stdout
	let fields = {
				\ 'name': a:1,  
				\ 'stderr':[], 
				\ 'stdout':[]
				\ }

	" populate the instace with on_stdout, on_stderr ... functions. These are
	" needed by jobstart.
	let instance = extend(copy(g:Go), fields)

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

let job1 = Go.cmd('build', '.', 'errors')

" vim:ts=4:sw=4:et

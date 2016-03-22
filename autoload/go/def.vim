if go#vimproc#has_vimproc()
	let s:vim_system = get(g:, 'gocomplete#system_function', 'vimproc#system2')
else
	let s:vim_system = get(g:, 'gocomplete#system_function', 'system')
endif

fu! s:system(str, ...)
	return call(s:vim_system, [a:str] + a:000)
endf

function! go#def#Jump(mode)
	let bin_path = go#path#CheckBinPath("guru")
	if empty(bin_path)
		return
	endif

	let old_gopath = $GOPATH
	let $GOPATH = go#path#Detect()

	let fname = fnamemodify(expand("%"), ':p:gs?\\?/?')
	let command = printf("%s definition %s:#%s", bin_path, shellescape(fname), go#util#OffsetCursor())

	let out = s:system(command)

	call s:jump_to_declaration(out, a:mode)
	let $GOPATH = old_gopath
endfunction

function! s:jump_to_declaration(out, mode)
	let old_errorformat = &errorformat
	let &errorformat = "%f:%l:%c:\ %m"

	" strip line ending
	let out = split(a:out, go#util#LineEnding())[0]
	let parts = split(out, ':')

	" parts[0] contains filename
	let fileName = parts[0]

	" put the error format into location list so we can jump automatically to it
	lgetexpr a:out

	" needed for restoring back user setting this is because there are two
	" modes of switchbuf which we need based on the split mode
	let old_switchbuf = &switchbuf

	if a:mode == "tab"
		let &switchbuf = "usetab"
		if bufloaded(fileName) == 0
			tab split
		endif
	elseif a:mode  == "split"
		split
	elseif a:mode == "vsplit"
		vsplit
	endif

	" Remove anything newer than the current position, just like basic
	" vim tag support
	if w:go_stack_level == 0
		let w:go_stack = []
	else
		let w:go_stack = w:go_stack[0:w:go_stack_level-1]
	endif

	" increment the stack counter
	let w:go_stack_level += 1

	" push it on to the jumpstack
	let ident = parts[3]
	let stack_entry = {'line': line("."), 'col': col("."), 'file': expand('%:p'), 'ident': ident}
	call add(w:go_stack, stack_entry)

	" jump to file now
	sil ll 1
	normal! zz

	let &switchbuf = old_switchbuf
	let &errorformat = old_errorformat
endfunction

function! go#def#SelectStackEntry()
	let target_window = go#ui#GetReturnWindow()
	if empty(target_window)
		let target_window = winnr()
	endif
	let highlighted_stack_entry = matchstr(getline("."), '^..\zs\(\d\+\)')
	if !empty(highlighted_stack_entry)
		execute target_window . "wincmd w"
		call go#def#Stack(str2nr(highlighted_stack_entry))
	endif
	call go#ui#CloseWindow()
endfunction

function! go#def#StackUI()
	if len(w:go_stack) == 0
		call go#util#EchoError("godef stack empty")
		return
	endif

	let stackOut = ['" <Up>,<Down>:navigate <Enter>:jump <Esc>,q:exit']

	let i = 0
	while i < len(w:go_stack)
		let entry = w:go_stack[i]
		let prefix = ""

		if i == w:go_stack_level
			let prefix = ">"
		else
			let prefix = " "
		endif

		call add(stackOut, printf("%s %d %s|%d col %d|%s", 
					\ prefix, i+1, entry["file"], entry["line"], entry["col"], entry["ident"]))
		let i += 1
	endwhile

	if w:go_stack_level == i
		call add(stackOut, "> ")
	endif

	call go#ui#OpenWindow("GoDef Stack", stackOut, "godefstack")
	noremap <buffer> <silent> <CR>  :<C-U>call go#def#SelectStackEntry()<CR>
	noremap <buffer> <silent> <Esc> :<C-U>call go#ui#CloseWindow()<CR>
	noremap <buffer> <silent> q     :<C-U>call go#ui#CloseWindow()<CR>
endfunction

function! go#def#StackClear(...)
	let w:go_stack = []
	let w:go_stack_level = 0
endfunction

function! go#def#StackPop(...)
	if len(w:go_stack) == 0
		call go#util#EchoError("godef stack empty")
		return
	endif

	if w:go_stack_level == 0
		call go#util#EchoError("at bottom of the godef stack")
		return
	endif

	if !len(a:000)
		let numPop = 1
	else
		let numPop = a:1
	endif

	let newLevel = str2nr(w:go_stack_level) - str2nr(numPop)
	call go#def#Stack(newLevel + 1)
endfunction

function! go#def#Stack(...)
	if len(w:go_stack) == 0
		call go#util#EchoError("godef stack empty")
		return
	endif

	if !len(a:000)
		" Display interactive stack
		call go#def#StackUI()
		return
	else
		let jumpTarget = a:1
	endif

	if jumpTarget !~ '^\d\+$'
		if jumpTarget !~ '^\s*$'
			call go#util#EchoError("location must be a number")
		endif
		return
	endif

	let jumpTarget = str2nr(jumpTarget) - 1

	if jumpTarget >= 0 && jumpTarget < len(w:go_stack)
		let w:go_stack_level = jumpTarget
		let target = w:go_stack[w:go_stack_level]

		" jump
		let old_errorformat = &errorformat
		let &errorformat = "%f:%l:%c"

		" put the error format into location list so we can jump automatically to it
		lgetexpr printf("%s:%s:%s", target["file"], target["line"], target["col"])

		sil ll 1
		normal! zz

		let &errorformat = old_errorformat
	else
		call go#util#EchoError("invalid location. Try :GoDefStack to see the list of valid entries")
	endif
endfunction


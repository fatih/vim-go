if !exists("g:go_godef_bin")
	let g:go_godef_bin = "godef"
endif

if go#vimproc#has_vimproc()
	let s:vim_system = get(g:, 'gocomplete#system_function', 'vimproc#system2')
else
	let s:vim_system = get(g:, 'gocomplete#system_function', 'system')
endif

fu! s:system(str, ...)
	return call(s:vim_system, [a:str] + a:000)
endf

" modified and improved version of vim-godef
function! go#def#Jump(...)
	if !len(a:000)
		" gives us the offset of the word, basically the position of the word under
		" the cursor
		let arg = s:getOffset()
	else
		let arg = a:1
	endif

	let bin_path = go#path#CheckBinPath(g:go_godef_bin)
	if empty(bin_path)
		return
	endif

	let old_gopath = $GOPATH
	let $GOPATH = go#path#Detect()

	let fname = fnamemodify(expand("%"), ':p:gs?\\?/?')
	let command = bin_path . " -t -f=" . shellescape(fname) . " -i " . shellescape(arg)

	" get output of godef
	let out = s:system(command, join(getbufline(bufnr('%'), 1, '$'), go#util#LineEnding()))

	" First line is <file>:<line>:<col>
	" Second line is <identifier><space><type>
	let godefout=split(out, go#util#LineEnding())

	" jump to it
	call s:godefJump(godefout, "")
	let $GOPATH = old_gopath
endfunction


function! go#def#JumpMode(mode)
	let arg = s:getOffset()

	let bin_path = go#path#CheckBinPath(g:go_godef_bin)
	if empty(bin_path)
		return
	endif

	let old_gopath = $GOPATH
	let $GOPATH = go#path#Detect()

	let fname = fnamemodify(expand("%"), ':p:gs?\\?/?')
	let command = bin_path . " -t -f=" . shellescape(fname) . " -i " . shellescape(arg)

	" get output of godef
	let out = s:system(command, join(getbufline(bufnr('%'), 1, '$'), go#util#LineEnding()))

	" First line is <file>:<line>:<col>
	" Second line is <identifier><space><type>
	let godefout=split(out, go#util#LineEnding())

	" jump to it
	call s:godefJump(godefout, a:mode)
	let $GOPATH = old_gopath
endfunction


function! s:getOffset()
	let pos = getpos(".")[1:2]
	if &encoding == 'utf-8'
		let offs = line2byte(pos[0]) + pos[1] - 2
	else
		let c = pos[1]
		let buf = line('.') == 1 ? "" : (join(getline(1, pos[0] - 1), go#util#LineEnding()) . go#util#LineEnding())
		let buf .= c == 1 ? "" : getline(pos[0])[:c-2]
		let offs = len(iconv(buf, &encoding, "utf-8"))
	endif

	let argOff = "-o=" . offs
	return argOff
endfunction


function! s:godefJump(out, mode)
	let old_errorformat = &errorformat
	let &errorformat = "%f:%l:%c"

	" Location is the first line of godef output. Ideally in the proper format
	" but it could also be an error
	let location = a:out[0]

	" Echo the godef error if we had one.
	if location =~ 'godef: '
		let gderr=substitute(location, go#util#LineEnding() . '$', '', '')
        call go#util#EchoError(gderr)
		" Don't jump if we're in a modified buffer
	elseif getbufvar(bufnr('%'), "&mod")
		call go#util#EchoError("No write since last change")
	else
		let parts = split(a:out[0], ':')

		" parts[0] contains filename
		let fileName = parts[0]

        " Don't jump if it's the same identifier we just jumped to
        if len(w:go_stack) > 0 && w:go_stack[w:go_stack_level-1]['ident'] == a:out[1] && w:go_stack[w:go_stack_level-1]['file'] == fileName
            return
        endif

		" needed for restoring back user setting this is because there are two
		" modes of switchbuf which we need based on the split mode
		let old_switchbuf = &switchbuf

		if a:mode == "tab"
			let &switchbuf = "usetab"

			if bufloaded(fileName) == 0
				tab split
			endif
		else
			if a:mode  == "split"
				split
			elseif a:mode == "vsplit"
				vsplit
			endif
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
        call add(w:go_stack,
            \{'line': line("."), 'col': col("."),
            \'file': expand('%:p'), 'ident': a:out[1]})

		" jump to file now
        call s:goToFileLocation(location)
	end
endfunction

function! go#def#StackPrint()
    if len(w:go_stack) == 0
        call go#util#EchoError("godef stack empty")
        return
    endif
    let i = 0
    while i < len(w:go_stack)
        let entry = w:go_stack[i]
        if i == w:go_stack_level
            echon "> "
        else
            echon "  "
        endif
        echon i+1 . " "
        echohl Directory
        echon entry["file"]
        echohl None
        echon "|"
        echohl LineNr
        echon entry["line"] . " col " . entry["col"]
        echohl None
        echon "|"
        echon entry["ident"] . "\n"
        let i += 1
    endwhile
    if w:go_stack_level == i
        echo ">"
    endif
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
    call go#def#StackJump(newLevel + 1)
endfunction

function! go#def#StackJump(...)
    if len(w:go_stack) == 0
        call go#util#EchoError("godef stack empty")
        return
    endif
	if !len(a:000)
        " Display interactive stack
        call go#def#StackPrint()
        echon "\n"
        let jumpTarget=input("Type number and <Enter> (empty cancels): ")
	else
		let jumpTarget= a:1
	endif

    if jumpTarget !~ '^\d\+$'
        if jumpTarget !~ '^\s*$'
            call go#util#EchoError("location must be a number")
        endif
        return
    endif

    let jumpTarget=str2nr(jumpTarget) - 1
    if jumpTarget >= 0 && jumpTarget < len(w:go_stack)
        let w:go_stack_level = jumpTarget
        let target = w:go_stack[w:go_stack_level]

        " jump
        call s:goToFileLocation(target["file"], target["line"], target["col"])
    else
        call go#util#EchoError("invalid godef stack location. Try :GoDefJump to see the list of valid entries")
    endif
endfunction

function! s:goToFileLocation(...)
	let old_errorformat = &errorformat
	let &errorformat = "%f:%l:%c"

    " put the error format into location list so we can jump automatically to
    " it
    if a:0 == 3
        lgetexpr printf("%s:%s:%s", a:1, a:2, a:3)
    elseif a:0 == 1
        lgetexpr a:1
    else
        lgetexpr ""
    endif

    sil ll 1
    normal zz

    let &errorformat = old_errorformat
endfunction

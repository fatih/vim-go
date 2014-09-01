if exists("g:go_loaded_godef")
	finish
endif
let g:go_loaded_godef = 1


" modified and improved version of vim-godef
function! Godef(...)
	if !len(a:000)
		" gives us the offset of the word, basicall the position of the word under
		" he cursor
		let arg = s:getOffset()
	else
		let arg = a:1
	endif

	let command = g:go_godef_bin . " -f=" . expand("%:p") . " -i " . shellescape(arg)

	" get output of godef
	let out=system(command, join(getbufline(bufnr('%'), 1, '$'), "\n"))

	" jump to it
	call GodefJump(out, "")
endfunction


function! GodefTab()
	let arg = s:getOffset()

	let command = g:go_godef_bin . " -f=" . expand("%:p") . " -i " . shellescape(arg)

	" get output of godef
	let out=system(command, join(getbufline(bufnr('%'), 1, '$'), "\n"))

	call GodefJump(out, "tab")
endfunction


function! s:getOffset()
	let pos = getpos(".")[1:2]
	if &encoding == 'utf-8'
		let offs = line2byte(pos[0]) + pos[1] - 2
	else
		let c = pos[1]
		let buf = line('.') == 1 ? "" : (join(getline(1, pos[0] - 1), "\n") . "\n")
		let buf .= c == 1 ? "" : getline(pos[0])[:c-2]
		let offs = len(iconv(buf, &encoding, "utf-8"))
	endif

	let argOff = "-o=" . offs
	return argOff
endfunction


function! GodefJump(out, mode)
	let old_errorformat = &errorformat
	let &errorformat = "%f:%l:%c"

	if a:out =~ 'godef: '
		let out=substitute(a:out, '\n$', '', '')
		echom out
	else
		let parts = split(a:out, ':')
		" parts[0] contains filename
		let fileName = parts[0]

		" put the error format into location list so we can jump automatically to
		" it
		lgetexpr a:out

		let old_switchbuf = &switchbuf

		if a:mode == "tab"
			let &switchbuf = "usetab"

			if bufloaded(fileName) == 0
				tab split 
			endif

		endif

		" jump to file now
		ll 1

		let &switchbuf = old_switchbuf
	end
	let &errorformat = old_errorformat
endfunction

nnoremap <silent> <Plug>(go-def) :<C-u>call Godef()<CR>
nnoremap <silent> <Plug>(go-def-vertical) :vsp <CR>:<C-u>call Godef()<CR>
nnoremap <silent> <Plug>(go-def-split) :sp <CR>:<C-u>call Godef()<CR>
nnoremap <silent> <Plug>(go-def-tab) :<CR>:<C-u>call GodefTab()<CR>

command! -range -nargs=* GoDef :call Godef(<f-args>)

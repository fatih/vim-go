if exists("g:go_loaded_godef")
  finish
endif
let g:go_loaded_godef = 1

" modified and improved version of vim-godef
function! Godef(...)
    if !len(a:000)
	let pos = getpos(".")[1:2]
	if &encoding == 'utf-8'
	    let offs = line2byte(pos[0]) + pos[1] - 2
	else
	    let c = pos[1]
	    let buf = line('.') == 1 ? "" : (join(getline(1, pos[0] - 1), "\n") . "\n")
	    let buf .= c == 1 ? "" : getline(pos[0])[:c-2]
	    let offs = len(iconv(buf, &encoding, "utf-8"))
	endif

	let arg = "-o=" . offs
    else
        let arg = a:1
    endif

    let out=system(g:go_godef_bin . " -f=" . expand("%:p") . " -i " . shellescape(arg), join(getbufline(bufnr('%'), 1, '$'), "\n"))

    let old_errorformat = &errorformat
    let &errorformat = "%f:%l:%c"

    if out =~ 'godef: '
        let out=substitute(out, '\n$', '', '')
        echom out
    else
        lexpr out
    end
    let &errorformat = old_errorformat
endfunction

autocmd FileType go nnoremap <buffer> gd :call Godef()<cr>

command! -range -nargs=* GoDef :call Godef(<f-args>)

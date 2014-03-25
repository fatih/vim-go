if !exists("g:godef_command")
    let g:godef_command = "godef"
endif

if !exists("g:godef_split")
    let g:godef_split = 1
endif

if !exists("g:godef_same_file_in_same_window")
    let g:godef_same_file_in_same_window=0
endif


function! GodefUnderCursor()
    let pos = getpos(".")[1:2]
    if &encoding == 'utf-8'
        let offs = line2byte(pos[0]) + pos[1] - 2
    else
        let c = pos[1]
        let buf = line('.') == 1 ? "" : (join(getline(1, pos[0] - 1), "\n") . "\n")
        let buf .= c == 1 ? "" : getline(pos[0])[:c-2]
        let offs = len(iconv(buf, &encoding, "utf-8"))
    endif
    silent call Godef("-o=" . offs)
endfunction

function! Godef(arg)
    let out=system(g:godef_command . " -f=" . expand("%:p") . " -i " . shellescape(a:arg), join(getbufline(bufnr('%'), 1, '$'), "\n"))

    let old_errorformat = &errorformat
    let &errorformat = "%f:%l:%c"

    if out =~ 'godef: '
        let out=substitute(out, '\n$', '', '')
        echom out
    elseif g:godef_same_file_in_same_window == 1 && (out) =~ "^".expand("%:p")
        let x=stridx(out, ":")
        let out=expand("%").strpart(out, x, len(out)-x)
        lexpr out
    else
        if g:godef_split == 1
            split
        elseif g:godef_split == 2
            tabnew
        endif
        lexpr out
    end
    let &errorformat = old_errorformat
endfunction

autocmd FileType go nnoremap <buffer> gd :call GodefUnderCursor()<cr>
command! -range -nargs=1 Godef :call Godef(<q-args>)

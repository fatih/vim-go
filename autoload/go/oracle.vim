" -*- text -*-
"  oracle.vim -- Vim integration for the Go oracle.
"
"  Load with (e.g.)  :source oracle.vim
"  Call with (e.g.)  :GoOracleDescribe
"  while cursor or selection is over syntax of interest.
"  Run :copen to show the quick-fix file.
"
" This is an absolutely rudimentary integration of the Go Oracle into
" Vim's quickfix mechanism and it needs a number of usability
" improvements before it can be practically useful to Vim users.
" Voluntary contributions welcomed!
"
" TODO(adonovan):
" - reject buffers with no filename.
" - hide all filenames in quickfix buffer.
"
"
func! s:qflist(output)
    let qflist = []
    " Parse GNU-style 'file:line.col-line.col: message' format.
    let mx = '^\(\a:[\\/][^:]\+\|[^:]\+\):\(\d\+\):\(\d\+\):\(.*\)$'
    for line in split(a:output, "\n")
        let ml = matchlist(line, mx)
        " Ignore non-match lines or warnings
        if ml == [] || ml[4] =~ '^ warning:'
            continue
        endif
        let item = {
                    \  'filename': ml[1],
                    \  'text': ml[4],
                    \  'lnum': ml[2],
                    \  'col': ml[3],
                    \}
        let bnr = bufnr(fnameescape(ml[1]))
        if bnr != -1
            let item['bufnr'] = bnr
        endif
        call add(qflist, item)
    endfor
    call setqflist(qflist)
    cwindow
endfun

func! s:getpos(l, c)
    if &encoding != 'utf-8'
        let buf = a:l == 1 ? '' : (join(getline(1, a:l-1), "\n") . "\n")
        let buf .= a:c == 1 ? '' : getline('.')[:a:c-2]
        return len(iconv(buf, &encoding, 'utf-8'))
    endif
    return line2byte(a:l) + (a:c-2)
endfun

func! s:RunOracle(mode, selected) range abort
    let fname = expand('%:p')
    let dname = expand('%:p:h')
    let pkg = go#package#ImportPath(dname)
    if exists('g:go_oracle_scope_file')
        let sname = get(g:, 'go_oracle_scope_file')
    elseif pkg != -1
        let sname = pkg
    else
        let sname = fname
    endif

    if a:selected != -1
        let pos1 = s:getpos(line("'<"), col("'<"))
        let pos2 = s:getpos(line("'>"), col("'>"))
        let cmd = printf('%s -format json -pos=%s:#%d,#%d %s %s',
                    \  g:go_oracle_bin,
                    \  shellescape(fname), pos1, pos2, a:mode, shellescape(sname))
    else
        let pos = s:getpos(line('.'), col('.'))
        let cmd = printf('%s -format json -pos=%s:#%d %s %s',
                    \  g:go_oracle_bin,
                    \  shellescape(fname), pos, a:mode, shellescape(sname))
    endif

    " echo '# ' . cmd . ' #'
    echon "vim-go: " | echohl Identifier | echon "analysing ..." | echohl None
    let out = system(cmd)
    if v:shell_error
        " echohl WarningMsg | echo out | echohl None
        " echoerr out
        return {}
    else
        let json_decoded = webapi#json#decode(out)
        return json_decoded
    endif
endfun

let s:buf_nr = -1

" Show 'implements' relation for selected package
function! go#oracle#Implements(selected)
    let out = s:RunOracle('implements', a:selected)
    if empty(out)
        redraw | echon "vim-go: could not run static analyser."
        return
    endif

    " be sure they exists before we retrieve them from the map
    if !has_key(out, "implements")
        return
    endif

    if has_key(out.implements, "from")
        let interfaces = out.implements.from
    elseif has_key(out.implements, "fromptr")
        let interfaces = out.implements.fromptr
    else
        redraw | echon "vim-go: " | echon "does not satisfy any interface"| echohl None
        return
    endif

    " get the type name and kind from the type under the cursor
    let typeName = out.implements.type.name

    " prepare the title
    let title = typeName . " implements:"

    " start to populate our buffer content
    let result  = [title, ""]

    for interface in interfaces
        " don't add runtime interfaces
        if interface.name !~ '^runtime'
            let line = interface.name . "\t" . interface.pos
            call add(result, line)
        endif
    endfor

    " reuse existing buffer window if it exists otherwise create a new one
    if !bufexists(s:buf_nr)
        execute 'rightbelow new'
        file `="[Implements]"`
        let s:buf_nr = bufnr('%')
    elseif bufwinnr(s:buf_nr) == -1
        execute 'rightbelow new'
        execute s:buf_nr . 'buffer'
    elseif bufwinnr(s:buf_nr) != bufwinnr('%')
        execute bufwinnr(s:buf_nr) . 'wincmd w'
    endif


    " Keep minimum height to 10, if there is more just increase it that it
    " occupies all results
    let implements_height = 10
    if len(result) < implements_height
        exe 'resize ' . implements_height
    else
        exe 'resize ' . len(result)
    endif

    setlocal filetype=vimgo
    setlocal bufhidden=delete
    setlocal buftype=nofile
    setlocal noswapfile
    setlocal nobuflisted
    setlocal winfixheight
    setlocal cursorline " make it easy to distinguish

    " we need this to purge the buffer content
    setlocal modifiable

    "delete everything first from the buffer
    %delete _  

    " now add the content
    call append(0, result)

    " delete last line that comes from the append call
    $delete _  

    " set it back to non modifiable
    setlocal nomodifiable

    nnoremap <buffer> <CR> :call <SID>OpenDefinition()<CR>
endfunction

function! s:OpenDefinition()
    let curline = getline('.')

    " don't touch our first line and any blank line
    if curline =~ "implements" || curline =~ "^$"
        " supress information about calling this function
        echo "" 
        return
    endif

    " format: 'interface file:lnum:coln'
    let mx = '^\(^\S*\)\s*\(.\{-}\):\(\d\+\):\(\d\+\)'

    " parse it now into the list
    let tokens = matchlist(curline, mx)

    " convert to: 'file:lnum:coln'
    let expr = tokens[2] . ":" . tokens[3] . ":" .  tokens[4]

    " jump to it in a new tab, we use explicit lgetexpr so we can later change
    " the behaviour via settings (like opening in vsplit instead of tab)
    lgetexpr expr
    tab split
    ll 1

    " center the word 
    norm! zz 
endfunction


" Describe selected syntax: definition, methods, etc
function! go#oracle#Describe(selected)
    let out = s:RunOracle('describe', a:selected)
    let detail = out["describe"]["detail"]
    let desc = out["describe"]["desc"]

    echo '# detail: '. detail
    " package, constant, variable, type, function or statement labe
    if detail == "package"
        echo desc
        return
    endif

    if detail == "value"
        echo desc
        echo out["describe"]["value"]
        return
    endif

    " the rest needs to be implemented
    echo desc
endfunction

" Show possible targets of selected function call
function! go#oracle#Callees(selected)
    let out = s:RunOracle('callees', a:selected)
    echo out
endfunction

" Show possible callers of selected function
function! go#oracle#Callers(selected)
    let out = s:RunOracle('callers', a:selected)
    echo out
endfunction

" Show the callgraph of the current program.
function! go#oracle#Callgraph(selected)
    let out = s:RunOracle('callgraph', a:selected)
    echo out
endfunction

" Show path from callgraph root to selected function
function! go#oracle#Callstack(selected)
    let out = s:RunOracle('callstack', a:selected)
    echo out
endfunction

" Show free variables of selection
function! go#oracle#Freevars(selected)
    let out = s:RunOracle('freevars', a:selected)
    echo out
endfunction

" Show send/receive corresponding to selected channel op
function! go#oracle#Peers(selected)
    let out = s:RunOracle('peers', a:selected)
    echo out
endfunction

" Show all refs to entity denoted by selected identifier
function! go#oracle#Referrers(selected)
    let out = s:RunOracle('referrers', a:selected)
    echo out
endfunction

" vim:ts=4:sw=4:et

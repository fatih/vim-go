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
if exists("g:go_loaded_oracle")
  finish
endif
let g:go_loaded_oracle = 1

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
    let sname = shellescape(fname)
  endif

  if a:selected != -1
    let pos1 = s:getpos(line("'<"), col("'<"))
    let pos2 = s:getpos(line("'>"), col("'>"))
    let cmd = printf('%s -pos=%s:#%d,#%d %s %s',
      \  g:go_oracle_bin,
      \  shellescape(fname), pos1, pos2, a:mode, sname)
  else
    let pos = s:getpos(line('.'), col('.'))
    let cmd = printf('%s -pos=%s:#%d %s %s',
      \  g:go_oracle_bin,
      \  shellescape(fname), pos, a:mode, sname)
  endif

  let out = system(cmd)
  if v:shell_error
    echohl Error | echomsg out | echohl None
  else
    call s:qflist(out)
  endif
endfun

" Describe selected syntax: definition, methods, etc
command! -range=% GoOracleDescribe
  \ call s:RunOracle('describe', <count>)

" Show possible targets of selected function call
command! -range=% GoOracleCallees
  \ call s:RunOracle('callees', <count>)

" Show possible callers of selected function
command! -range=% GoOracleCallers
  \ call s:RunOracle('callers', <count>)

" Show the callgraph of the current program.
command! -range=% GoOracleCallgraph
  \ call s:RunOracle('callgraph', <count>)

" Show path from callgraph root to selected function
command! -range=% GoOracleCallstack
  \ call s:RunOracle('callstack', <count>)

" Show free variables of selection
command! -range=% GoOracleFreevars
  \ call s:RunOracle('freevars', <count>)

" Show 'implements' relation for selected package
command! -range=% GoOracleImplements
  \ call s:RunOracle('implements', <count>)

" Show send/receive corresponding to selected channel op
command! -range=% GoOracleChannelPeers
  \ call s:RunOracle('peers', <count>)

" Show all refs to entity denoted by selected identifier
command! -range=% GoOracleReferrers
  \ call s:RunOracle('referrers', <count>)

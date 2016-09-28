"  guru.vim -- Vim integration for the Go guru.

" guru_cmd returns a dict that contains the command to execute guru. option
" is dict with following options:
"  mode        : guru mode, such as 'implements'
"  format      : output format, either 'plain' or 'json'
"  needs_scope : if 1, adds the current package to the scope
"  selected    : if 1, means it's a range of selection, otherwise it picks up the
"                offset under the cursor
" example output:
"  {'cmd' : ['guru', '-json', 'implements', 'demo/demo.go:#66']}
func! s:guru_cmd(args) range abort
  let mode = a:args.mode
  let format = a:args.format
  let needs_scope = a:args.needs_scope
  let selected = a:args.selected

  let result = {}
  let dirname = expand('%:p:h')
  let pkg = go#package#ImportPath(dirname)

  " this is important, check it!
  if pkg == -1 && needs_scope
    return {'err': "current directory is not inside of a valid GOPATH"}
  endif

  "return with a warning if the binary doesn't exist
  let bin_path = go#path#CheckBinPath("guru") 
  if empty(bin_path)
    return {'err': "bin path not found"}
  endif

  " start constructing the command
  let cmd = [bin_path]

  let filename = fnamemodify(expand("%"), ':p:gs?\\?/?')
  let stdin_content = ""
  if &modified
    let sep = go#util#LineEnding()
    let content  = join(getline(1, '$'), sep )
    let result.stdin_content = filename . "\n" . strlen(content) . "\n" . content
    call add(cmd, "-modified")
  endif

  " enable outputting in json format
  if format == "json" 
    call add(cmd, "-json")
  endif

  " check for any tags
  if exists('g:go_guru_tags')
    let tags = get(g:, 'go_guru_tags')
    call extend(cmd, ["-tags", tags])
    call result.tags = tags
  endif

  " some modes require scope to be defined (such as callers). For these we
  " choose a sensible setting, which is using the current file's package
  let scopes = []
  if needs_scope
    let scopes = [pkg]
  endif

  " check for any user defined scope setting. users can define the scope,
  " in package pattern form. examples:
  "  golang.org/x/tools/cmd/guru # a single package
  "  golang.org/x/tools/...      # all packages beneath dir
  "  ...                         # the entire workspace.
  if exists('g:go_guru_scope')
    " check that the setting is of type list
    if type(get(g:, 'go_guru_scope')) != type([])
      return {'err' : "go_guru_scope should of type list"}
    endif

    let scopes = get(g:, 'go_guru_scope')
  endif

  " now add the scope to our command if there is any
  if !empty(scopes)
    " strip trailing slashes for each path in scoped. bug:
    " https://github.com/golang/go/issues/14584
    let scopes = go#util#StripTrailingSlash(scopes)

    " create shell-safe entries of the list
    if !has('job') | let scopes = go#util#Shelllist(scopes) | endif

    " guru expect a comma-separated list of patterns, construct it
    let l:scope = join(scopes, ",")
    let result.scope = l:scope
    call extend(cmd, ["-scope", l:scope])
  endif

  let pos = printf("#%s", go#util#OffsetCursor())
  if selected != -1
    " means we have a range, get it
    let pos1 = go#util#Offset(line("'<"), col("'<"))
    let pos2 = go#util#Offset(line("'>"), col("'>"))
    let pos = printf("#%s,#%s", pos1, pos2)
  endif

  let filename .= ':'.pos
  call extend(cmd, [mode, filename])

  let result.cmd = cmd
  return result
endfunction

" run_guru runs guru in sync mode with the given arguments
func! s:run_guru(args) abort
  let result = s:guru_cmd(a:args)
  if has_key(result, 'err')
    return result
  endif

  if a:args.needs_scope
    call go#util#EchoProgress("analysing with scope ". result.scope . " ...")
  elseif a:args.mode !=# 'what'
    " the query might take time, let us give some feedback
    call go#util#EchoProgress("analysing ...")
  endif

  let old_gopath = $GOPATH
  let $GOPATH = go#path#Detect()

  " run, forrest run!!!
  let command = join(result.cmd, " ")
  if &modified
    let out = go#util#System(command, result.stdin_content)
  else
    let out = go#util#System(command)
  endif

  let $GOPATH = old_gopath
  if go#util#ShellError() != 0
    " the output contains the error message
    return {'err' : out}
  endif

  return {'out': out}
endfunc

" run_guru_job runs guru in async mode with the given arguments
func! s:run_guru_job(args) abort
  if !has('job')
    return {'err': "job feature is not available"}
  endif

  let result = s:guru_cmd(a:args)
  if has_key(result, 'err')
    return result
  endif

  if a:args.needs_scope
    call go#util#EchoProgress("analysing with scope ". result.scope . " ...")
  elseif a:args.mode !=# 'what'
    " the query might take time, let us give some feedback
    call go#util#EchoProgress("analysing ...")
  endif

  " autowrite is not enabled for jobs
  call go#cmd#autowrite()

  let messages = []
  function! s:callback(chan, msg) closure
    call add(messages, a:msg)
  endfunction

  function! s:close_cb(chan) closure
    let l:job = ch_getjob(a:chan)
    let l:info = job_info(l:job)

    " only print guru call errors, not build errors. Build errors are parsed
    " below and showed in the quickfix window
    if l:info.exitval != 0 && len(messages) == 1
      call go#util#EchoError(messages[0])
      return
    endif

    let old_errorformat = &errorformat
    let errformat = "%f:%l.%c-%[%^:]%#:\ %m,%f:%l:%c:\ %m"
    call go#list#ParseFormat("locationlist", errformat, messages)

    let errors = go#list#Get("locationlist")
    call go#list#Window("locationlist", len(errors))
  endfunction

  let start_options = {
        \ 'callback': function("s:callback"),
        \ 'close_cb': function("s:close_cb"),
        \ }

  if &modified
    let l:tmpname = tempname()
    call writefile(split(result.stdin_content, "\n"), l:tmpname, "b")
    let l:start_options.in_io = "file"
    let l:start_options.in_name = l:tmpname
  endif

  let job = job_start(result.cmd, start_options)
  return {'job': job}
endfunc

" Report the possible constants, global variables, and concrete types that may
" appear in a value of type error
function! go#guru#Whicherrs(selected)
  let args = {
        \ 'mode': 'whicherrs',
        \ 'format': 'plain',
        \ 'selected': a:selected,
        \ 'needs_scope': 1,
        \ }

  let out = s:run_guru(args)
  if has_key(out, 'err')
    call go#util#EchoError(out.err)
    return
  endif

  if empty(out.out)
    call go#util#EchoSuccess("no error variables found. Try to change the scope with :GoGuruScope")
    return
  endif

  call s:loclistSecond(out.out)
endfunction

" Show 'implements' relation for selected package
function! go#guru#Implements(selected)
  let args = {
        \ 'mode': 'implements',
        \ 'format': 'plain',
        \ 'selected': a:selected,
        \ 'needs_scope': 1,
        \ }

  if has('job') | return s:run_guru_job(args) | endif

  let out = s:run_guru(args)
  if has_key(out, 'err')
    call go#util#EchoError(out.err)
    return
  endif

  call s:loclistSecond(out.out)
endfunction

" Describe selected syntax: definition, methods, etc
function! go#guru#Describe(selected)
  let args = {
        \ 'mode': 'describe',
        \ 'format': 'plain',
        \ 'selected': a:selected,
        \ 'needs_scope': 1,
        \ }

  let out = s:run_guru(args)
  if has_key(out, 'err')
    call go#util#EchoError(out.err)
    return
  endif

  call s:loclistSecond(out.out)
endfunction

" Show possible targets of selected function call
function! go#guru#Callees(selected)
  let args = {
        \ 'mode': 'callees',
        \ 'format': 'plain',
        \ 'selected': a:selected,
        \ 'needs_scope': 1,
        \ }

  let out = s:run_guru(args)
  if has_key(out, 'err')
    call go#util#EchoError(out.err)
    return
  endif

  call s:loclistSecond(out.out)
endfunction

" Show possible callers of selected function
function! go#guru#Callers(selected)
  let args = {
        \ 'mode': 'callers',
        \ 'format': 'plain',
        \ 'selected': a:selected,
        \ 'needs_scope': 1,
        \ }

  let out = s:run_guru(args)
  if has_key(out, 'err')
    call go#util#EchoError(out.err)
    return
  endif

  call s:loclistSecond(out.out)
endfunction

" Show path from callgraph root to selected function
function! go#guru#Callstack(selected)
  let args = {
        \ 'mode': 'callstack',
        \ 'format': 'plain',
        \ 'selected': a:selected,
        \ 'needs_scope': 1,
        \ }

  let out = s:run_guru(args)
  if has_key(out, 'err')
    call go#util#EchoError(out.err)
    return
  endif

  call s:loclistSecond(out.out)
endfunction

" Show free variables of selection
function! go#guru#Freevars(selected)
  " Freevars requires a selection
  if a:selected == -1
    call go#util#EchoError("GoFreevars requires a selection (range) of code")
    return
  endif

  let args = {
        \ 'mode': 'freevars',
        \ 'format': 'plain',
        \ 'selected': 1,
        \ 'needs_scope': 0,
        \ }

  let out = s:run_guru(args)
  if has_key(out, 'err')
    call go#util#EchoError(out.err)
    return
  endif

  call s:loclistSecond(out.out)
endfunction

" Show send/receive corresponding to selected channel op
function! go#guru#ChannelPeers(selected)
  let args = {
        \ 'mode': 'peers',
        \ 'format': 'plain',
        \ 'selected': a:selected,
        \ 'needs_scope': 1,
        \ }
  let out = s:run_guru(args)
  if has_key(out, 'err')
    call go#util#EchoError(out.err)
    return
  endif

  call s:loclistSecond(out.out)
endfunction

" Show all refs to entity denoted by selected identifier
function! go#guru#Referrers(selected)
  let args = {
        \ 'mode': 'referrers',
        \ 'format': 'plain',
        \ 'selected': a:selected,
        \ 'needs_scope': 0,
        \ }

  let out = s:run_guru(args)
  if has_key(out, 'err')
    call go#util#EchoError(out.err)
    return
  endif

  call s:loclistSecond(out.out)
endfunction

function! go#guru#SameIdsTimer()
  call timer_start(200, function('go#guru#SameIds'), {'repeat': -1})
endfunction

function! go#guru#SameIds()
  " we use matchaddpos() which was introduce with 7.4.330, be sure we have
  " it: http://ftp.vim.org/vim/patches/7.4/7.4.330
  if !exists("*matchaddpos")
    call go#util#EchoError("GoSameIds is supported with Vim version 7.4-330 or later")
    return
  endif

  " json_encode() and friends are introduced with this patch (7.4.1304)
  " vim: https://groups.google.com/d/msg/vim_dev/vLupTNhQhZ8/cDGIk0JEDgAJ
  " nvim: https://github.com/neovim/neovim/pull/4131        
  if !exists("*json_decode")
    call go#util#EchoError("GoSameIds is not supported due old version of Vim/Neovim")
    return
  endif

  let args = {
        \ 'mode': 'what',
        \ 'format': 'json',
        \ 'selected': -1,
        \ 'needs_scope': 0,
        \ }

  let out = s:run_guru(args)
  if has_key(out, 'err')
    call go#util#EchoError(out.err)
    return
  endif

  call s:same_ids_highlight(out.out)
endfunction

function! s:same_ids_highlight(output)
  call go#guru#ClearSameIds() " run after calling guru to reduce flicker.

  let result = json_decode(a:output)
  if type(result) != v:t_dict && !get(g:, 'go_auto_sameids', 0)
    call go#util#EchoError("malformed output from guru")
    return
  endif

  if !has_key(result, 'sameids')
    if !get(g:, 'go_auto_sameids', 0)
      call go#util#EchoError("no same_ids founds for the given identifier")
    endif
    return
  endif

  let poslen = 0
  for enclosing in result['enclosing']
    if enclosing['desc'] == 'identifier'
      let poslen = enclosing['end'] - enclosing['start']
      break
    endif
  endfor

  " return when there's no identifier to highlight.
  if poslen == 0
    return
  endif

  let same_ids = result['sameids']
  " highlight the lines
  for item in same_ids
    let pos = split(item, ':')
    call matchaddpos('goSameId', [[str2nr(pos[-2]), str2nr(pos[-1]), str2nr(poslen)]])
  endfor

  if get(g:, "go_auto_sameids", 0)
    " re-apply SameIds at the current cursor position at the time the buffer
    " is redisplayed: e.g. :edit, :GoRename, etc.
    autocmd BufWinEnter <buffer> nested call go#guru#SameIds(-1)
  endif
endfunction

function! go#guru#ClearSameIds()
  let m = getmatches()
  for item in m
    if item['group'] == 'goSameId'
      call matchdelete(item['id'])
    endif
  endfor

  " remove the autocmds we defined
  if exists("#BufWinEnter<buffer>")
    autocmd! BufWinEnter <buffer>
  endif
endfunction

function! go#guru#ToggleSameIds(selected)
  if len(getmatches()) != 0 
    call go#guru#ClearSameIds()
  else
    call go#guru#SameIds(a:selected)
  endif
endfunction

function! go#guru#AutoToogleSameIds()
  if get(g:, "go_auto_sameids", 0)
    call go#util#EchoProgress("sameids auto highlighting disabled")
    call go#guru#ClearSameIds()
    let g:go_auto_sameids = 0
    return
  endif

  call go#util#EchoSuccess("sameids auto highlighting enabled")
  let g:go_auto_sameids = 1
endfunction


""""""""""""""""""""""""""""""""""""""""
"" HELPER FUNCTIONS
""""""""""""""""""""""""""""""""""""""""

" This uses Vim's errorformat to parse the output from Guru's 'plain output
" and put it into location list. I believe using errorformat is much more
" easier to use. If we need more power we can always switch back to parse it
" via regex.
func! s:loclistSecond(output)
  " backup users errorformat, will be restored once we are finished
  let old_errorformat = &errorformat

  " match two possible styles of errorformats:
  "
  "   'file:line.col-line2.col2: message'
  "   'file:line:col: message'
  "
  " We discard line2 and col2 for the first errorformat, because it's not
  " useful and location only has the ability to show one line and column
  " number
  let errformat = "%f:%l.%c-%[%^:]%#:\ %m,%f:%l:%c:\ %m"
  call go#list#ParseFormat("locationlist", errformat, split(a:output, "\n"))

  let errors = go#list#Get("locationlist")
  call go#list#Window("locationlist", len(errors))
endfun

function! go#guru#Scope(...)
  if a:0
    if a:0 == 1 && a:1 == '""'
      unlet g:go_guru_scope
      call go#util#EchoSuccess("guru scope is cleared")
    else
      let g:go_guru_scope = a:000
      call go#util#EchoSuccess("guru scope changed to: ". join(a:000, ","))
    endif

    return
  endif

  if !exists('g:go_guru_scope')
    call go#util#EchoError("guru scope is not set")
  else
    call go#util#EchoSuccess("current guru scope: ". join(g:go_guru_scope, ","))
  endif
endfunction

function! go#guru#Tags(...)
  if a:0
    if a:0 == 1 && a:1 == '""'
      unlet g:go_guru_tags
      call go#util#EchoSuccess("guru tags is cleared")
    else
      let g:go_guru_tags = a:1
      call go#util#EchoSuccess("guru tags changed to: ". a:1)
    endif

    return
  endif

  if !exists('g:go_guru_tags')
    call go#util#EchoSuccess("guru tags is not set")
  else
    call go#util#EchoSuccess("current guru tags: ". a:1)
  endif
endfunction

" vim: sw=2 ts=2 et

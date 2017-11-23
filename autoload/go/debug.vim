if !exists('g:go_debug_windows')
  let g:go_debug_windows = {
        \ 'stack': 'leftabove 20vnew',
        \ 'out':   'botright 10new',
        \ 'vars':  'leftabove 30vnew',
        \ }
endif

if !exists('g:go_debug_address')
  let g:go_debug_address = '127.0.0.1:8181'
endif

if !exists('s:state')
  let s:state = {
  \ 'rpcid': 1,
  \ 'breakpoint': {},
  \ 'currentThread': {},
  \ 'localVars': {},
  \ 'functionArgs': {},
  \ 'message': [],
  \}

  if go#util#HasDebug('debug')
    let g:go_debug_diag = s:state
  endif
endif

function! s:groutineID() abort
  return s:state['currentThread'].goroutineID
endfunction

function! s:exit(job, status) abort
  if has_key(s:state, 'job')
    call remove(s:state, 'job')
  endif
  call s:clearState()
  if a:status > 0
    call go#util#EchoError(s:state['message'])
  endif

  if get(s:state, 'tmpdir', '') isnot ''
    call delete(s:state['tmpdir'], 'rf')
    let s:state['tmpdir'] = ''
  endif
endfunction

function! s:logger(prefix, ch, msg) abort
  let winnum = bufwinnr(bufnr('__GODEBUG_OUTPUT__'))
  if winnum == -1
    return
  endif
  exe winnum 'wincmd w'
  setlocal modifiable
  if getline(1) == ''
    call setline('$', a:prefix . a:msg)
  else
    call append('$', a:prefix . a:msg)
  endif
  normal! G
  setlocal nomodifiable
  wincmd p
endfunction

function! s:call_jsonrpc(method, ...) abort
  if len(a:000) > 0 && type(a:000[0]) == v:t_func
     let Cb = a:000[0]
     let args = a:000[1:]
  else
     let Cb = v:none
     let args = a:000
  endif
  let s:state['rpcid'] += 1
  let json = json_encode({
  \  'id': s:state['rpcid'],
  \  'method': a:method,
  \  'params': args,
  \})
  try
    if type(Cb) == v:t_func
      let s:ch = ch_open('127.0.0.1:8181', {'mode': 'nl', 'callback': Cb})
      call ch_sendraw(s:ch, json)
      return
    endif
    let ch = ch_open('127.0.0.1:8181', {'mode': 'nl', 'timeout': 20000})
    call ch_sendraw(ch, json)
    let json = ch_readraw(ch)
    let obj = json_decode(json)
    if type(obj) == v:t_dict && has_key(obj, 'error') && !empty(obj.error)
      throw obj.error
    endif
    return obj
  catch
    throw substitute(v:exception, '^Vim', '', '')
  endtry
endfunction

function! s:update_breakpoint(res) abort
  if type(a:res) ==# v:t_none
    return
  endif
  let state = a:res.result.State
  if !has_key(state, 'currentThread')
    return
  endif
  let s:state['currentThread'] = state.currentThread
  let bufs = filter(map(range(1, winnr('$')), '[v:val,bufname(winbufnr(v:val))]'), 'v:val[1]=~"\.go$"')
  if len(bufs) == 0
    return
  endif
  exe bufs[0][0] 'wincmd w'
  let filename = state.currentThread.file
  let linenr = state.currentThread.line
  let oldfile = fnamemodify(expand('%'), ':p:gs!\\!/!')
  if oldfile != filename
    silent! exe 'edit' filename
  endif
  silent! exe 'norm!' linenr.'G'
  silent! normal! zvzz
  silent! sign unplace 9999
  silent! exe 'sign place 9999 line=' . linenr . ' name=godebugcurline file=' . filename
endfunction

function! s:show_stacktrace(res) abort
  if !has_key(a:res, 'result')
    return
  endif
  let winnum = bufwinnr(bufnr('__GODEBUG_STACKTRACE__'))
  if winnum == -1
    return
  endif
  exe winnum 'wincmd w'
  setlocal modifiable
  silent %delete _
  for i in range(len(a:res.result.Locations))
    let loc = a:res.result.Locations[i]
    call setline(i+1, printf('%s - %s:%d', loc.function.name, fnamemodify(loc.file, ':.p'), loc.line))
  endfor
  setlocal nomodifiable
  wincmd p
endfunction

function! s:show_variables() abort
  let winnum = bufwinnr(bufnr('__GODEBUG_VARIABLES__'))
  if winnum == -1
    return
  endif
  exe winnum 'wincmd w'
  setlocal modifiable
  silent %delete _

  let v = []
  let v += ['# Local Variables']
  for c in s:state['localVars']
    let v += split(s:eval_tree(c, 0), "\n")
  endfor
  let v += ['']
  let v += ['# Function Arguments']
  for c in s:state['functionArgs']
    let v += split(s:eval_tree(c, 0), "\n")
  endfor
  call setline(1, v)

  setlocal nomodifiable
  wincmd p
endfunction

function! s:clearState() abort
  let s:state['currentThread'] = {}
  let s:state['localVars'] = {}
  let s:state['functionArgs'] = {}
  silent! sign unplace 9999
endfunction

function! s:stop() abort
  call s:clearState()
  if has_key(s:state, 'job')
    call job_stop(s:state['job'], 'kill')
    call remove(s:state, 'job')
  endif
endfunction

function! go#debug#Stop() abort
  for k in keys(s:state['breakpoint'])
    let bt = s:state['breakpoint'][k]
    if bt.id >= 0
      silent exe 'sign unplace ' . bt.id
    endif
  endfor

  for k in filter(map(split(execute('command GoDebug'), "\n")[1:], 'matchstr(v:val,"^\\s*\\zs\\S\\+")'), 'v:val!="GoDebugStart"')
    exe 'delcommand' k
  endfor
  for k in map(split(execute('map <Plug>(go-debug-'), "\n")[1:], 'matchstr(v:val,"^n\\s\\+\\zs\\S\\+")')
    exe 'unmap' k
  endfor

  command! -nargs=* -complete=customlist,go#package#Complete GoDebugStart call go#debug#Start(<f-args>)

  call s:stop()

  let bufs = filter(map(range(1, winnr('$')), '[v:val,bufname(winbufnr(v:val))]'), 'v:val[1]=~"\.go$"')
  if len(bufs) > 0
    exe bufs[0][0] 'wincmd w'
  else
    wincmd p
  endif
  silent! exe bufwinnr(bufnr('__GODEBUG_STACKTRACE__')) 'wincmd c'
  silent! exe bufwinnr(bufnr('__GODEBUG_VARIABLES__')) 'wincmd c'
  silent! exe bufwinnr(bufnr('__GODEBUG_OUTPUT__')) 'wincmd c'

  set noballooneval
  set balloonexpr=
endfunction

function! s:goto_file() abort
  let m = matchlist(getline('.'), ' - \(.*\):\([0-9]\+\)$')
  if m[1] == ''
    return
  endif
  let bufs = filter(map(range(1, winnr('$')), '[v:val,bufname(winbufnr(v:val))]'), 'v:val[1]=~"\.go$"')
  if len(bufs) == 0
    return
  endif
  exe bufs[0][0] 'wincmd w'
  let filename = m[1]
  let linenr = m[2]
  let oldfile = fnamemodify(expand('%'), ':p:gs!\\!/!')
  if oldfile != filename
    silent! exe 'edit' filename
  endif
  silent! exe 'norm!' linenr.'G'
  silent! normal! zvzz
endfunction

function! s:delete_expands()
  let nr = line('.')
  while 1
    let l = getline(nr+1)
    if empty(l) || l =~ '^\S'
      return
    endif
    silent! exe (nr+1) . 'd _'
  endwhile
  silent! exe 'norm!' nr.'G'
endfunction

function! s:expand_var() abort
  " Get name from struct line.
  let name = matchstr(getline('.'), '^[^:]\+\ze: [a-zA-Z0-9\.·]\+{\.\.\.}$')
  " Anonymous struct
  if name == '' 
    let name = matchstr(getline('.'), '^[^:]\+\ze: struct {.\{-}}$')
  endif

  if name != ''
    setlocal modifiable
    let not_open = getline(line('.')+1) !~ '^ '
    let l = line('.')
    call s:delete_expands()

    if not_open
      call append(l, split(s:eval(name), "\n")[1:])
    endif
    silent! exe 'norm!' l.'G'
    setlocal nomodifiable
    return
  endif

  " Expand maps
  let m = matchlist(getline('.'), '^[^:]\+\ze: map.\{-}\[\(\d\+\)\]$')
  if len(m) > 0 && m[1] != ''
    setlocal modifiable
    let not_open = getline(line('.')+1) !~ '^ '
    let l = line('.')
    call s:delete_expands()
    if not_open
      " TODO: Not sure how to do this yet... Need to get keys of the map.
      " let vs = ''
      " for i in range(0, min([10, m[1]-1]))
      "   let vs .= ' ' . s:eval(printf("%s[%s]", m[0], ))
      " endfor
      " call append(l, split(vs, "\n"))
    endif

    silent! exe 'norm!' l.'G'
    setlocal nomodifiable
    return
  endif

  " Expand string and slice.
  " TODO: Expand string, too
  " g:go_debug_diag["localVars"][1].children[0].children[0]
  let m = matchlist(getline('.'), '^\([^:]\+\)\ze: \(\[\]\w\{-}\|string\)\[\([0-9]\+\)\]$')
  if len(m) > 0 && m[1] != ''
    setlocal modifiable
    let not_open = getline(line('.')+1) !~ '^ '
    let l = line('.')
    call s:delete_expands()

    if not_open
      let vs = ''
      for i in range(0, min([10, m[3]-1]))
        let vs .= ' ' . s:eval(m[1] . '[' . i . ']')
      endfor
      call append(l, split(vs, "\n"))
    endif
    silent! exe 'norm!' l.'G'
    setlocal nomodifiable
    return
  endif
endfunction

function! s:start_cb(ch, json) abort
  let res = json_decode(a:json)
  if type(res) == v:t_dict && has_key(res, 'error') && !empty(res.error)
    throw res.error
  endif
  if empty(res) || !has_key(res, 'result')
    return
  endif
  for bt in res.result.Breakpoints
    if bt.id >= 0
      let s:state['breakpoint'][bt.id] = bt
      exe 'sign place '. bt.id .' line=' . bt.line . ' name=godebugbreakpoint file=' . bt.file
    endif
  endfor

  let oldbuf = bufnr('%')
  silent! only!

  let winnum = bufwinnr(bufnr('__GODEBUG_STACKTRACE__'))
  if winnum != -1
    return
  endif

  if exists('g:go_debug_windows["stack"]') && g:go_debug_windows['stack'] != ''
    exe 'silent ' . g:go_debug_windows['stack']
    silent file `='__GODEBUG_STACKTRACE__'`
    setlocal buftype=nofile bufhidden=wipe nomodified nobuflisted noswapfile nowrap nonumber nocursorline
    setlocal filetype=godebugstacktrace
    nmap <buffer> <cr> :<c-u>call <SID>goto_file()<cr>
    nmap <buffer> q <Plug>(go-debug-stop)
  endif

  if exists('g:go_debug_windows["out"]') && g:go_debug_windows['out'] != ''
    exe 'silent ' . g:go_debug_windows['out']
    silent file `='__GODEBUG_OUTPUT__'`
    setlocal buftype=nofile bufhidden=wipe nomodified nobuflisted noswapfile nowrap nonumber nocursorline
    setlocal filetype=godebugoutput
    nmap <buffer> q <Plug>(go-debug-stop)
  endif

  if exists('g:go_debug_windows["vars"]') && g:go_debug_windows['vars'] != ''
    exe 'silent ' . g:go_debug_windows['vars']
    silent file `='__GODEBUG_VARIABLES__'`
    setlocal buftype=nofile bufhidden=wipe nomodified nobuflisted noswapfile nowrap nonumber nocursorline
    setlocal filetype=godebugvariables
    call append(0, ["# Local Variables", "", "# Function Arguments"])
    nmap <buffer> <silent> <cr> :<c-u>call <SID>expand_var()<cr>
    nmap <buffer> q <Plug>(go-debug-stop)
  endif

  delcommand GoDebugStart
  command! -nargs=0 GoDebugBreakpoint call go#debug#Breakpoint()
  command! -nargs=0 GoDebugContinue   call go#debug#Stack('continue')
  command! -nargs=0 GoDebugNext       call go#debug#Stack('next')
  command! -nargs=0 GoDebugStep       call go#debug#Stack('step')
  command! -nargs=0 GoDebugStepIn     call go#debug#Stack('stepin')
  command! -nargs=0 GoDebugStepOut    call go#debug#Stack('stepout')
  command! -nargs=0 GoDebugRestart    call go#debug#Restart()
  command! -nargs=0 GoDebugStop       call go#debug#Stop()
  command! -nargs=* GoDebugSet        call go#debug#Set(<f-args>)
  command! -nargs=1 GoDebugEval       call go#debug#Eval(<q-args>)
  command! -nargs=* GoDebugCommand    call go#debug#Command(<f-args>)

  nnoremap <silent> <Plug>(go-debug-breakpoint) :<C-u>call go#debug#Breakpoint()<CR>
  nnoremap <silent> <Plug>(go-debug-next)       :<C-u>call go#debug#Stack('next')<CR>
  nnoremap <silent> <Plug>(go-debug-step)       :<C-u>call go#debug#Stack('step')<CR>
  nnoremap <silent> <Plug>(go-debug-stepin)     :<C-u>call go#debug#Stack('stepin')<CR>
  nnoremap <silent> <Plug>(go-debug-stepout)    :<C-u>call go#debug#Stack('stepout')<CR>
  nnoremap <silent> <Plug>(go-debug-continue)   :<C-u>call go#debug#Stack('continue')<CR>
  nnoremap <silent> <Plug>(go-debug-stop)       :<C-u>call go#debug#Stop()<CR>
  nnoremap <silent> <Plug>(go-debug-eval)       :<C-u>call go#debug#Eval(expand('<cword>'))<CR>

  nmap <F5> <Plug>(go-debug-continue)
  nmap <F6> <Plug>(go-debug-eval)
  nmap <F9> <Plug>(go-debug-breakpoint)
  nmap <F10> <Plug>(go-debug-next)
  nmap <F11> <Plug>(go-debug-step)

  set balloonexpr=go#debug#BalloonExpr()
  set ballooneval

  augroup GoDebugExit
    autocmd VimLeave *
          \  if get(s:state, 'tmpdir', '') isnot ''
          \|   call delete(s:state['tmpdir'], 'rf')
          \| endif
  augroup end

  augroup GoDebugWindow
    au!
    au BufWipeout __GODEBUG_STACKTRACE__ call go#debug#Stop()
    au BufWipeout __GODEBUG_VARIABLES__ call go#debug#Stop()
    au BufWipeout __GODEBUG_OUTPUT__ call go#debug#Stop()
  augroup END
  exe bufwinnr(oldbuf) 'wincmd w'
endfunction

function! s:starting(ch, msg) abort
  call go#util#EchoProgress(a:msg)
  let s:state['message'] += [a:msg]
  if stridx(a:msg, g:go_debug_address) != -1
    call ch_setoptions(a:ch, {
    \ 'out_cb': function('s:logger', ['OUT: ']),
    \ 'err_cb': function('s:logger', ['ERR: ']),
    \})
    call s:call_jsonrpc('RPCServer.ListBreakpoints', function('s:start_cb'))
  endif
endfunction

" Start the debug mode. The first argument is the package name to compile and
" debug, anything else will be passed to the running program.
function! go#debug#Start(...) abort
  if has('nvim')
    call go#util#EchoError('This feature only works in Vim for now; Neovim is not (yet) supported. Sorry :-(')
    return
  endif
  if !go#util#has_job()
    call go#util#EchoError('This feature requires Vim 8.0.0087 or newer with +job.')
    return
  endif

  " It's already running.
  if has_key(s:state, 'job') && job_status(s:state['job']) == 'run'
    return
  endif

  if go#util#HasDebug('debug')
    let g:go_debug_diag = s:state
  endif

  let l:is_test = bufname('')[-8:] is# '_test.go'

  let dlv = go#path#CheckBinPath("dlv")
  if empty(dlv)
    return
  endif

  try
    if len(a:000) > 0
      let l:pkgname = a:1
      " Expand .; otherwise this won't work from a tmp dir.
      if l:pkgname[0] == '.'
        let l:pkgname = go#package#FromPath(getcwd()) . l:pkgname[1:]
      endif
    else
      let l:pkgname = go#package#FromPath(getcwd())
    endif

    let l:args = []
    if len(a:000) > 1
      let l:args = ['--'] + a:000[1:]
    endif

    " Run dlv from a temporary directory so it won't put the binary in the
    " current dir. We pass --wd= so the binary is still run from the current
    " dir.
    if !l:is_test
      let original_dir = getcwd()
      let s:state['tmpdir'] = go#util#tempdir('vim-go-debug-')
      exe 'lcd ' . s:state['tmpdir']
    endif

    if l:is_test
      let l:cmd = [dlv, 'test', l:pkgname]
    else
      let l:cmd = [dlv, 'debug', l:pkgname, '--wd', l:original_dir]
    endif
    let l:cmd += [
          \ '--headless',
          \ '--api-version', '2',
          \ '--log',
          \ '--listen', g:go_debug_address,
          \ '--accept-multiclient',
    \]
    if get(g:, 'go_build_tags', '') isnot ''
      let l:cmd += ['--build-flags', '--tags=' . g:go_build_tags]
    endif
    let l:cmd += l:args

    call go#util#EchoProgress('Starting GoDebug...')
    let s:state['message'] = []
    let job = job_start(l:cmd, {
      \ 'out_cb': function('s:starting'),
      \ 'err_cb': function('s:starting'),
      \ 'exit_cb': function('s:exit'),
      \ 'stoponexit': 'kill',
    \})
    let ch = job_getchannel(job)
    let s:state['job'] = job
  catch
    call go#util#EchoError(v:exception)
  finally
    if !l:is_test
      exe 'lcd ' . original_dir
    endif
  endtry
endfunction

" Translate a reflect kind constant to a human string.
function! s:reflect_kind(k)
  " Kind constants from Go's reflect package.
  return [
        \ 'Invalid Kind',
        \ 'Bool',
        \ 'Int',
        \ 'Int8',
        \ 'Int16',
        \ 'Int32',
        \ 'Int64',
        \ 'Uint',
        \ 'Uint8',
        \ 'Uint16',
        \ 'Uint32',
        \ 'Uint64',
        \ 'Uintptr',
        \ 'Float32',
        \ 'Float64',
        \ 'Complex64',
        \ 'Complex128',
        \ 'Array',
        \ 'Chan',
        \ 'Func',
        \ 'Interface',
        \ 'Map',
        \ 'Ptr',
        \ 'Slice',
        \ 'String',
        \ 'Struct',
        \ 'UnsafePointer',
  \ ][a:k]
endfunction

function! s:eval_tree(var, nest) abort
  if a:var.name =~ '^\~'
    return ''
  endif
  let nest = a:nest
  let v = ''
  let kind = s:reflect_kind(a:var.kind)
  if !empty(a:var.name)
    let v .= repeat(' ', nest) . a:var.name . ': '

    if kind == 'Bool'
      let v .= printf("%s\n", a:var.value)
    elseif kind == 'Struct'
      " Anonymous struct
      if a:var.type[:8] == 'struct { '
        let v .= printf("%s\n", a:var.type)
      else
        let v .= printf("%s{...}\n", a:var.type)
      endif
    elseif kind == 'Slice' || kind == 'String' || kind == 'Map' || kind == 'Array'
      let v .= printf("%s[%d]\n", a:var.type, a:var.len)
    elseif kind == 'Chan' || kind == 'Func' || kind == 'Interface'
      let v .= printf("%s\n", a:var.type)
    elseif kind == 'Ptr'
      " TODO: We can do something more useful here.
      let v .= printf("%s\n", a:var.type)
    elseif kind == 'Complex64' || kind == 'Complex128'
      let v .= printf("%s%s\n", a:var.type, a:var.value)
    " Int, Float
    else
      let v .= printf("%s(%s)\n", a:var.type, a:var.value)
    endif
  else
    let nest -= 1
  endif
  if index(['Chan', 'Complex64', 'Complex128'], kind) == -1 && a:var.type != 'error'
    for c in a:var.children
      let v .= s:eval_tree(c, nest+1)
    endfor
  endif
  return v
endfunction

function! s:eval(arg) abort
  try
    let res = s:call_jsonrpc('RPCServer.State')
    let goroutineID = res.result.State.currentThread.goroutineID
    let res = s:call_jsonrpc('RPCServer.Eval', {'expr': a:arg, 'scope':{'GoroutineID': goroutineID}})
    return s:eval_tree(res.result.Variable, 0)
  catch
    call go#util#EchoError(v:exception)
  endtry
  return ''
endfunction

function! go#debug#BalloonExpr() abort
  return s:eval(v:beval_text)
endfunction

function! go#debug#Eval(arg) abort
  try
    echo s:eval(a:arg)
  catch
    call go#util#EchoError(v:exception)
  endtry
endfunction

function! go#debug#Command(...) abort
  try
    let res = s:call_jsonrpc('RPCServer.Command', {'name': join(a:000, ' ')})
    call s:update_breakpoint(res)
  catch
    call go#util#EchoError(v:exception)
  endtry
endfunction

function! s:update_variables() abort
  let vars = [
  \{
  \  'method': 'RPCServer.ListLocalVars',
  \  'kind': 'localVars',
  \  'bind': 'Variables',
  \},
  \{
  \  'method': 'RPCServer.ListFunctionArgs',
  \  'kind': 'functionArgs',
  \  'bind': 'Args',
  \}
  \]
  for v in vars
    try
      let res = s:call_jsonrpc(v.method, {'scope':{'GoroutineID': s:groutineID()}})
      let s:state[v.kind] = res.result[v.bind]
    catch
      call go#util#EchoError(v:exception)
    endtry
  endfor
  call s:show_variables()
endfunction

function! go#debug#Set(symbol, value) abort
  try
    let res = s:call_jsonrpc('RPCServer.State')
    let goroutineID = res.result.State.currentThread.goroutineID
    call s:call_jsonrpc('RPCServer.Set', {'symbol': a:symbol, 'value': a:value, 'scope':{'GoroutineID': goroutineID}})
  catch
    call go#util#EchoError(v:exception)
  endtry
  call s:update_variables()
endfunction

function! s:update_stacktrace() abort
  try
    let res = s:call_jsonrpc('RPCServer.Stacktrace', {'id': s:groutineID(), 'depth': 5})
    call s:show_stacktrace(res)
  catch
    call go#util#EchoError(v:exception)
  endtry
endfunction

function! s:stack_cb(ch, json) abort
  let s:stack_name = ''
  let res = json_decode(a:json)
  if type(res) == v:t_dict && has_key(res, 'error') && !empty(res.error)
    call go#util#EchoError(res.error)
    call s:clearState()
    call go#debug#Restart()
    return
  endif
  if empty(res) || !has_key(res, 'result')
    return
  endif
  call s:update_breakpoint(res)
  call s:update_stacktrace()
  call s:update_variables()
endfunction

function! go#debug#Stack(name) abort
  let name = a:name
  if len(s:state['breakpoint']) == 0
    try
      let res = s:call_jsonrpc('RPCServer.FindLocation', {'loc': 'main.main'})
      let res = s:call_jsonrpc('RPCServer.CreateBreakpoint', {'Breakpoint':{'addr': res.result.Locations[0].pc}})
      let bt = res.result.Breakpoint
      let s:state['breakpoint'][bt.id] = bt
      let name = 'continue'
    catch
      call go#util#EchoError(v:exception)
    endtry
  endif
  try
    if name == 'next' && get(s:, 'stack_name', '') == 'next'
      call s:call_jsonrpc('RPCServer.CancelNext')
    endif
    let s:stack_name = name
    let res = s:call_jsonrpc('RPCServer.Command', function('s:stack_cb'), {'name': name})
  catch
    call go#util#EchoError(v:exception)
  endtry
endfunction

function! go#debug#Restart() abort
  try
    call s:clearState()
    let res = s:call_jsonrpc('RPCServer.Restart')
  catch
    call go#util#EchoError(v:exception)
  endtry
endfunction

function! go#debug#Breakpoint() abort
  let filename = fnamemodify(expand('%'), ':p:gs!\\!/!')
  let linenr = line('.')
  try
    let found = v:none
    for k in keys(s:state.breakpoint)
      let bt = s:state.breakpoint[k]
      if bt.file == filename && bt.line == linenr
        let found = bt
        break
      endif
    endfor
    if type(found) == v:t_dict
      call remove(s:state['breakpoint'], bt.id)
      let res = s:call_jsonrpc('RPCServer.ClearBreakpoint', {'id': found.id})
      exe 'sign unplace '. found.id .' file=' . found.file
    else
      let res = s:call_jsonrpc('RPCServer.CreateBreakpoint', {'Breakpoint':{'file': filename, 'line': linenr}})
      let bt = res.result.Breakpoint
      let s:state['breakpoint'][bt.id] = bt
      exe 'sign place '. bt.id .' line=' . bt.line . ' name=godebugbreakpoint file=' . bt.file
    endif
  catch
    call go#util#EchoError(v:exception)
  endtry
endfunction

sign define godebugbreakpoint text=> texthl=GoDebugBreakpoint
sign define godebugcurline text== linehl=GoDebugCurrent texthl=GoDebugCurrent

fun! s:hi()
  hi GoDebugBreakpoint term=standout ctermbg=8  ctermfg=0 guibg=#BAD4F5  guifg=Black
  hi GoDebugCurrent    term=reverse  ctermbg=12 ctermfg=7 guibg=DarkBlue guifg=White
endfun
augroup vim-go-breakpoint
  autocmd!
  autocmd ColorScheme * call s:hi()
augroup end
call s:hi()

" vim: sw=2 ts=2 et

if !executable('dlv')
  finish
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
endif

let s:addr = '127.0.0.1:8181'

function! s:groutineID() abort
  return s:state['currentThread'].goroutineID
endfunction

function! s:exit(job, status) abort
  if has_key(s:state, 'job')
    call remove(s:state, 'job')
  endif
  if a:status != 0
    echohl Error | echo join(s:state['message'], "\n") . "\n" | echohl None
	call getchar()
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

function! go#debug#Diag() abort
  let g:go_debug_diag = s:state
  echo s:state
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
    call setline(i+1, printf('%s - %s:%d', loc.function.name, fnamemodify(loc.file, ':p'), loc.line))
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

function! s:stop() abort
  let s:state['breakpoint'] = {}
  let s:state['currentThread'] = {}
  if has_key(s:state, 'job')
    call job_stop(s:state['job'], 'kill')
    call remove(s:state, 'job')
  endif
endfunction

function! go#debug#Stop() abort
  sign unplace 9999
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

function! s:expand_var() abort
  let name = matchstr(getline('.'), '^[^:]\+\ze: \.\.\.$')
  if name == ''
    return
  endif
  setlocal modifiable
  let l = line('.')
  silent! %g/^\s/d _
  call append(l, split(s:eval(name), "\n")[1:])
  silent! exe 'norm!' l.'G'
  setlocal nomodifiable
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

  silent leftabove 20vnew
  silent file `='__GODEBUG_STACKTRACE__'`
  setlocal buftype=nofile bufhidden=wipe nomodified nobuflisted noswapfile nowrap nonumber nocursorline
  setlocal filetype=godebugstacktrace
  nmap <buffer> <cr> :<c-u>call <SID>goto_file()<cr>
  nmap <buffer> q <Plug>(go-debug-stop)

  silent botright 10new
  silent file `='__GODEBUG_OUTPUT__'`
  setlocal buftype=nofile bufhidden=wipe nomodified nobuflisted noswapfile nowrap nonumber nocursorline
  setlocal filetype=godebugoutput
  nmap <buffer> q <Plug>(go-debug-stop)

  silent leftabove 30vnew
  silent file `='__GODEBUG_VARIABLES__'`
  setlocal buftype=nofile bufhidden=wipe nomodified nobuflisted noswapfile nowrap nonumber nocursorline
  setlocal filetype=godebugvariables
  call append(0, ["# Local Variables", "", "# Function Arguments"])
  nmap <buffer> <cr> :<c-u>call <SID>expand_var()<cr>
  nmap <buffer> q <Plug>(go-debug-stop)

  command! -nargs=0 GoDebugDiag call go#debug#Diag()
  command! -nargs=0 GoDebugToggleBreakpoint call go#debug#ToggleBreakpoint()
  command! -nargs=0 GoDebugContinue call go#debug#Stack('continue')
  command! -nargs=0 GoDebugNext call go#debug#Stack('next')
  command! -nargs=0 GoDebugStep call go#debug#Stack('step')
  command! -nargs=0 GoDebugStepIn call go#debug#Stack('stepin')
  command! -nargs=0 GoDebugStepOut call go#debug#Stack('stepout')
  command! -nargs=0 GoDebugRestart call go#debug#Restart()
  command! -nargs=0 GoDebugStop call go#debug#Stop()
  command! -nargs=* GoDebugSet call go#debug#Set(<f-args>)
  command! -nargs=1 GoDebugEval call go#debug#Eval(<q-args>)
  command! -nargs=* GoDebugCommand call go#debug#Command(<f-args>)

  nnoremap <silent> <Plug>(go-debug-diag) :<C-u>call go#debug#Diag()<CR>
  nnoremap <silent> <Plug>(go-debug-toggle-breakpoint) :<C-u>call go#debug#ToggleBreakpoint()<CR>
  nnoremap <silent> <Plug>(go-debug-next) :<C-u>call go#debug#Stack('next')<CR>
  nnoremap <silent> <Plug>(go-debug-step) :<C-u>call go#debug#Stack('step')<CR>
  nnoremap <silent> <Plug>(go-debug-stepin) :<C-u>call go#debug#Stack('stepin')<CR>
  nnoremap <silent> <Plug>(go-debug-stepout) :<C-u>call go#debug#Stack('stepout')<CR>
  nnoremap <silent> <Plug>(go-debug-continue) :<C-u>call go#debug#Stack('continue')<CR>
  nnoremap <silent> <Plug>(go-debug-stop) :<C-u>call go#debug#Stop()<CR>
  nnoremap <silent> <Plug>(go-debug-eval) :<C-u>call go#debug#Eval(expand('<cword>'))<CR>

  nmap <F5> <Plug>(go-debug-continue)
  nmap <F6> <Plug>(go-debug-eval)
  nmap <F9> <Plug>(go-debug-toggle-breakpoint)
  nmap <F10> <Plug>(go-debug-next)
  nmap <F11> <Plug>(go-debug-step)

  set balloonexpr=go#debug#BalloonExpr()
  set ballooneval

  augroup GoDebugWindow
    au!
    au BufWipeout __GODEBUG_STACKTRACE__ call go#debug#Stop()
    au BufWipeout __GODEBUG_VARIABLES__ call go#debug#Stop()
    au BufWipeout __GODEBUG_OUTPUT__ call go#debug#Stop()
  augroup END
  exe bufwinnr(oldbuf) 'wincmd w'
endfunction

function! s:starting(ch, msg) abort
  echomsg a:msg
  let s:state['message'] += [a:msg]
  if stridx(a:msg, s:addr) != -1
    call ch_setoptions(a:ch, {
    \ 'out_cb': function('s:logger', ['OUT: ']),
    \ 'err_cb': function('s:logger', ['ERR: ']),
    \})
    call s:call_jsonrpc('RPCServer.ListBreakpoints', function('s:start_cb'))
  endif
endfunction

function! go#debug#Start(...) abort
  if has_key(s:state, 'job') && job_status(s:state['job']) == 'run'
    return
  endif
  try
    echohl SpecialKey | echomsg 'Starting GoDebug...' | echohl None
    let s:state['message'] = []
    let job = job_start('dlv debug --headless --api-version=2 --log --listen=' . s:addr . ' --accept-multiclient -- ' . join(a:000, ' '), {
    \ 'out_cb': function('s:starting'),
    \ 'err_cb': function('s:starting'),
    \ 'exit_cb': function('s:exit'),
    \ 'stoponexit': 'kill',
    \})
    let ch = job_getchannel(job)
    let s:state['job'] = job
  catch
    echohl Error | echomsg v:exception | echohl None
    return
  endtry
endfunction

function! s:eval_tree(var, nest) abort
  if a:var.name =~ '^\~'
    return ''
  endif
  let nest = a:nest
  let v = ''
  if !empty(a:var.name)
    if len(a:var.children) > 0 && a:var.value == ''
      let v .= repeat(' ', nest) . printf("%s: ...\n", a:var.name)
    else
      let v .= repeat(' ', nest) . printf("%s: %s\n", a:var.name, a:var.type == 'string' ? json_encode(a:var.value) : a:var.value)
    endif
  else
    let nest -= 1
  endif
  for c in a:var.children
    let v .= s:eval_tree(c, nest+1)
  endfor
  return v
endfunction

function! s:eval(arg) abort
  try
    let res = s:call_jsonrpc('RPCServer.State')
    let goroutineID = res.result.State.currentThread.goroutineID
    let res = s:call_jsonrpc('RPCServer.Eval', {'expr': a:arg, 'scope':{'GoroutineID': goroutineID}})
    return s:eval_tree(res.result.Variable, 0)
  catch
    echohl Error | echomsg v:exception | echohl None
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
    echohl Error | echomsg v:exception | echohl None
  endtry
endfunction

function! go#debug#Command(...) abort
  try
    let res = s:call_jsonrpc('RPCServer.Command', {'name': join(a:000, ' ')})
    call s:update_breakpoint(res)
  catch
    echohl Error | echomsg v:exception | echohl None
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
      echohl Error | echomsg v:exception | echohl None
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
    echohl Error | echomsg v:exception | echohl None
  endtry
  call s:update_variables()
endfunction

function! s:update_stacktrace() abort
  try
    let res = s:call_jsonrpc('RPCServer.Stacktrace', {'id': s:groutineID(), 'depth': 5})
    call s:show_stacktrace(res)
  catch
    echohl Error | echomsg v:exception | echohl None
  endtry
endfunction

function! s:stack_cb(ch, json) abort
  let s:stack_name = ''
  let res = json_decode(a:json)
  if type(res) == v:t_dict && has_key(res, 'error') && !empty(res.error)
    throw res.error
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
      echohl Error | echomsg v:exception | echohl None
    endtry
  endif
  try
    if name == 'next' && get(s:, 'stack_name', '') == 'next'
      call s:call_jsonrpc('RPCServer.CancelNext')
    endif
    let s:stack_name = name
    let res = s:call_jsonrpc('RPCServer.Command', function('s:stack_cb'), {'name': name})
  catch
    echohl Error | echomsg v:exception | echohl None
    return
  endtry
endfunction

function! go#debug#Restart() abort
  try
    let res = s:call_jsonrpc('RPCServer.Restart')
  catch
    echohl Error | echomsg v:exception | echohl None
  endtry
endfunction

function! go#debug#ToggleBreakpoint() abort
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
    echohl Error | echomsg v:exception | echohl None
  endtry
endfunction

hi GoDebugBreakpoint term=standout ctermbg=8 guibg=#BAD4F5
hi GoDebugCurrent term=reverse ctermbg=12 guibg=DarkBlue
sign define godebugbreakpoint text=> texthl=GoDebugBreakpoint
sign define godebugcurline text== linehl=GoDebugCurrent texthl=GoDebugCurrent

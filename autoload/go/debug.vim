if !exists('s:state')
  let s:state = {
  \ 'rpcid': 1,
  \ 'breakpoint': {},
  \}
endif

function! s:exit(job, status) abort
  call remove(s:state, 'job')
endfunction

function! s:err_cb(ch, msg) abort
  echomsg a:msg
endfunction

function! s:start() abort
  if !has_key(s:state, 'job')
    let job = job_start(['dlv', 'debug', '--headless', '--api-version=2', '--log', '--listen=127.0.0.1:8181', '--accept-multiclient'])
    call job_setoptions(job, {'exit_cb': function('s:exit'), 'stoponexit': 'kill'})
    let ch = job_getchannel(job)
    call ch_setoptions(job, {'err_cb': function('s:err_cb')})
    let s:state['job'] = job
    sleep 1
  endif
  let res = s:call_jsonrpc('RPCServer.ListBreakpoints')
  for bt in res.result.Breakpoints
    let s:state['breakpoint'][bt.id] = bt
    if bt.id >= 0
      exe "sign place ". bt.id ." line=" . bt.line . " name=godebugbreakpoint file=" . bt.file
    endif
  endfor
endfunction

function! s:call_jsonrpc(method, ...) abort
  let s:state['rpcid'] += 1
  let json = json_encode({
  \  'id': s:state['rpcid'],
  \  'method': a:method,
  \  'params': a:000,
  \})
  try
    if !has_key(s:state, 'ch')
      let s:state['ch'] = ch_open('127.0.0.1:8181')
      call ch_setoptions(s:state['ch'], {'mode': 'raw'})
    endif
    call ch_sendraw(s:state['ch'], json)
    let json = ch_readraw(s:state['ch'])
    let obj = json_decode(json)
    if type(obj) == 4 && has_key(obj, 'error') && !empty(obj.error)
      throw obj.error
    endif
    return obj
  catch
    call remove(s:state, 'ch')
    throw substitute(v:exception, '^Vim', '', '')
  endtry
endfunction

function! go#debug#Diag() abort
  echo s:state
endfunction

function! s:state(res) abort
  if a:res ==# v:none
    return
  endif
  let state = a:res.result.State
  if !has_key(state, 'currentThread')
    return
  endif
  let filename = state.currentThread.file
  let linenr = state.currentThread.line
  let oldfile = fnamemodify(expand('%'), ':p:gs!\\!/!')
  let s:state['currentThread'] = state.currentThread
  if oldfile != filename
    exe "edit" filename
  endif
  silent! exe 'norm!' linenr.'G'
  silent! normal! zvzz
  sign unplace 9999
  exe "sign place 9999 line=" . linenr . " name=godebugcurline file=" . filename
endfunction

function! go#debug#Connect() abort
  if !has_key(s:state, 'job') || !has_key(s:state, 'ch')
    try
      call s:start()
    catch
      echohl Error | echomsg v:exception | echohl None
    endtry
  endif
endfunction

function! go#debug#Eval(arg) abort
  try
    let res = s:call_jsonrpc('RPCServer.State')
    let goroutineID = res.result.State.currentThread.goroutineID
    let res = s:call_jsonrpc('RPCServer.Eval', {"expr": a:arg, "scope":{"GoroutineID": goroutineID}})
    echo res
  catch
    echohl Error | echomsg v:exception | echohl None
  endtry
endfunction

function! go#debug#Set(symbol, value) abort
  try
    let res = s:call_jsonrpc('RPCServer.State')
    let goroutineID = res.result.State.currentThread.goroutineID
    let res = s:call_jsonrpc('RPCServer.Set', {"symbol": a:symbol, "value": a:value, "scope":{"GoroutineID": goroutineID}})
    echo res
  catch
    echohl Error | echomsg v:exception | echohl None
  endtry
endfunction

function! go#debug#Stack(name) abort
  try
    let res = s:call_jsonrpc('RPCServer.Command', {"name": a:name})
    call s:state(res)
  catch
    echohl Error | echomsg v:exception | echohl None
  endtry
endfunction

function! go#debug#Stacktrace() abort
  try
    let res = s:call_jsonrpc('RPCServer.Stacktrace')
    echo res
  catch
    echohl Error | echomsg v:exception | echohl None
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
    if type(found) == 4
      call remove(s:state['breakpoint'], bt.id)
      let res = s:call_jsonrpc('RPCServer.ClearBreakpoint', {"id": found.id})
      exe "sign unplace ". found.id ." file=" . found.file
    else
      let res = s:call_jsonrpc('RPCServer.CreateBreakpoint', {"Breakpoint":{"file": filename, "line": linenr}})
      let bt = res.result.Breakpoint
      let s:state['breakpoint'][bt.id] = bt
      exe "sign place ". bt.id ." line=" . bt.line . " name=godebugbreakpoint file=" . bt.file
      "let res = s:call_jsonrpc('RPCServer.Checkpoint', {"Where": bt.addr})
    endif
  catch
    echohl Error | echomsg v:exception | echohl None
  endtry
endfunction

sign define godebugbreakpoint text=> texthl=Search
sign define godebugcurline text== texthl=DiffText


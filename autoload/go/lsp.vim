" don't spam the user when Vim is started in Vi compatibility mode
let s:cpo_save = &cpo
set cpo&vim

scriptencoding utf-8

let s:lspfactory = {}

function! s:lspfactory.get() dict abort
  if !has_key(self, 'current')
    " TODO(bc): check that the lsp is still running.
    let self.current = s:newlsp()
  endif

  return self.current
endfunction

function! s:lspfactory.reset() dict abort
  if has_key(self, 'current')
    call remove(self, 'current')
  endif
endfunction

function! s:newlsp()
  if !go#util#has_job()
    " TODO(bc): start the server in the background using a shell that waits for the right output before returning.
    call go#util#EchoError('This feature requires either Vim 8.0.0087 or newer with +job or Neovim.')
    return
  endif

  " job is the job used to talk to the backing instance of gopls.
  " ready is 0 until the initialize response has been received. 1 afterwards.
  " queue is messages to send after initialization
  " last_request_id is id of the most recently sent request.
  " buf is unprocessed/incomplete responses
  " handlers is request id -> callback
  let l:lsp = {
        \ 'job':  '',
        \ 'ready': 0,
        \ 'queue': [],
        \ 'last_request_id': 0,
        \ 'buf': '',
        \ 'handlers': {},
        \ }

  function! l:lsp.readMessage(data) dict abort
    let l:responses = []
    let l:rest = a:data

    while 1
      " Look for the end of the HTTP headers
      let l:body_start_idx = matchend(l:rest, "\r\n\r\n")

      if l:body_start_idx < 0
        " incomplete header
        break
      endif

      " Parse the Content-Length header.
      let l:header = l:rest[:l:body_start_idx - 4]
      let l:length_match = matchlist(
      \   l:header,
      \   '\vContent-Length: *(\d+)'
      \)

      if empty(l:length_match)
        " TODO(bc): shutdown gopls?
        throw "invalid JSON-RPC header:\n" . l:header
      endif

      " get the start of the rest
      let l:rest_start_idx = l:body_start_idx + str2nr(l:length_match[1])

      if len(l:rest) < l:rest_start_idx
        " incomplete response body
        break
      endif

      if go#util#HasDebug('lsp')
        let g:go_lsp_log = add(go#config#LspLog(), {
              \ 'response': l:rest[:l:rest_start_idx - 1]
        \ })
      endif

      let l:body = l:rest[l:body_start_idx : l:rest_start_idx - 1]
      let l:rest = l:rest[l:rest_start_idx :]

      try
        " add the json body to the list.
        call add(l:responses, json_decode(l:body))

        " TODO(bc): set status line stuff similarly to how job.vim handles it.
      catch
        " TODO(bc): log the message and/or show an error message.
      finally
        " intentionally left blank.
      endtry
    endwhile

    return [l:rest, l:responses]
  endfunction

  function! l:lsp.handleMessage(ch, data) dict abort
      let self.buf .= a:data

      let [self.buf, l:responses] = self.readMessage(self.buf)

      if self.ready is 0
        for l:response in l:responses
          " TODO(bc): handle notifications that aren't InitializeResult (e.g.
          " window/showMessage).
          call self.handleInitializeResult(l:response)
        endfor
      endif

      if self.ready is 1
        for l:response in l:responses
          if has_key(l:response, 'id') && has_key(self.handlers, l:response.id)
            try
              if has_key(l:response, 'error')
                call go#util#EchoError(l:response.error)
                return
              endif

              call call(self.handlers[l:response.id], [l:response.result])
            finally
              call remove(self.handlers, l:response.id)
            endtry
          endif
        endfor
      endif
  endfunction

  function! l:lsp.handleInitializeResult(response) dict abort
    " TODO(bc): send initialized message to the server?

    "if get(a:response, 'method', '') is# 'initialize'
    "  " TODO(bc): can this even happen?
    "  let self.ready = 1
    " elseif type(get(a:response, 'result')) is v:t_dict && has_key(a:response.result, 'capabilities')
    if type(get(a:response, 'result')) is v:t_dict && has_key(a:response.result, 'capabilities')
      " TODO(bc): store capabilities
      let self.ready = 1
    endif

    if self.ready is 0
      return
    endif

    " send messages queued while waiting for ready.
    for l:item in self.queue
      call self.sendMessage(l:item.data, l:item.handler)
    endfor

    " reset the queue
    let self.queue = []
  endfunction

  function! l:lsp.sendMessage(data, handler) dict abort
    if !self.last_request_id
      " TODO(bc): run a server per module and one per GOPATH? (may need to
      " keep track of servers by rootUri).
      let l:msg = self.newMessage(go#lsp#message#Initialize(getcwd()))

      " TODO(bc): update the statusline similarly to how job.vim does when
      " starting a job.
      call self.write(l:msg)
    endif

    if !self.ready
      call add(self.queue, {'data': a:data, 'handler': a:handler})
      return
    endif

    let l:msg = self.newMessage(a:data)
    if has_key(l:msg, 'id')
      let self.handlers[l:msg.id] = a:handler
    endif

    " TODO(bc): update the statusline similarly to how job.vim does when
    " starting a job.
    call self.write(l:msg)
  endfunction

  " newMessage returns a message constructed from data. data should be a dict
  " with 2 or 3 keys: notification, method, and optionally params.
  function! l:lsp.newMessage(data) dict abort
    let l:msg = {
          \ 'method': a:data.method,
          \ 'jsonrpc': '2.0',
          \ }

    if !a:data.notification
      let self.last_request_id += 1
      let l:msg.id = self.last_request_id
    endif

    if has_key(a:data, 'params')
      let l:msg.params = a:data.params
    endif

    return l:msg
  endfunction

  function! l:lsp.write(msg) dict abort
      let l:body = json_encode(a:msg)
      let l:data = 'Content-Length: ' . strlen(l:body) . "\r\n\r\n" . l:body

    if go#util#HasDebug('lsp')
      let g:go_lsp_log = add(go#config#LspLog(), {
            \ 'request':  l:data,
      \ })
    endif

    if has('nvim')
      call chansend(self.job, l:data)
      return
    endif

    call ch_sendraw(self.job, l:data)
  endfunction

  function! l:lsp.exit_cb(job, exit_status) dict abort
    call s:lspfactory.reset()
  endfunction
  " explicitly bind close_cb to state so that within it, self will always refer

  function! l:lsp.close_cb(ch) dict abort
    " TODO(bc): does anything need to be done here?
  endfunction

  function! l:lsp.err_cb(ch, msg) dict abort
    if go#util#HasDebug('lsp')
      let g:go_lsp_log = add(go#config#LspLog(), {
            \ 'stderr':  a:msg,
      \ })
    endif
  endfunction

  " explicitly bind callbacks to l:lsp so that within it, self will always refer
  " to l:lsp instead of l:opts. See :help Partial for more information.
  let l:opts = {
        \ 'in_mode': 'raw',
        \ 'out_mode': 'raw',
        \ 'err_mode': 'nl',
        \ 'noblock': 1,
        \ 'err_cb': funcref('l:lsp.err_cb', [], l:lsp),
        \ 'out_cb': funcref('l:lsp.handleMessage', [], l:lsp),
        \ 'close_cb': funcref('l:lsp.close_cb', [], l:lsp),
        \ 'exit_cb': funcref('l:lsp.exit_cb', [], l:lsp),
        \ 'cwd': getcwd(),
        \}

  let bin_path = go#path#CheckBinPath("gopls")
  if empty(bin_path)
    return
  endif

  " TODO(bc): output a message indicating which directory lsp is going to
  " start in.
  let l:lsp.job = go#job#Start('gopls', l:opts)

  " TODO(bc): send the initialize message now?
  return l:lsp
endfunction

function! s:noop()
endfunction

function! s:newHandlerState()
  " TODO(bc): capture the window id, set status, etc.
  let l:state = {
        \ 'winid': win_getid(winnr()),
      \ }

  return l:state
endfunction

" go#lsp#Definition calls gopls to get the definition of the identifier at
" line and col in fname. handler should be a dictionary function that takes a
" list of strings in the form 'file:line:col: message'. handler will be
" attached to a dictionary that manages state (statuslines, sets the winid,
" etc.)
function! go#lsp#Definition(fname, line, col, handler)
  function! s:definitionHandler(next, msg) abort dict
    " gopls returns a []Location; just take the first one.
    let l:msg = a:msg[0]
    let l:args = [[printf('%s:%d:%d: %s', go#path#FromURI(l:msg.uri), l:msg.range.start.line+1, l:msg.range.start.character+1, 'lsp does not supply a description')]]
    call call(a:next, l:args)
  endfunction

  let l:lsp = s:lspfactory.get()
  let l:state = s:newHandlerState()
  let l:msg = go#lsp#message#Definition(fnamemodify(a:fname, ':p'), a:line, a:col)
  call l:lsp.sendMessage(l:msg, funcref('s:definitionHandler', [function(a:handler, [], l:state)], l:state))
endfunction

" go#lsp#Type calls gopls to get the type definition of the identifier at
" line and col in fname. handler should be a dictionary function that takes a
" list of strings in the form 'file:line:col: message'. handler will be
" attached to a dictionary that manages state (statuslines, sets the winid,
" etc.)
function! go#lsp#TypeDef(fname, line, col, handler)
  function! s:typeDefinitionHandler(next, msg) abort dict
    " gopls returns a []Location; just take the first one.
    let l:msg = a:msg[0]
    let l:args = [[printf('%s:%d:%d: %s', go#path#FromURI(l:msg.uri), l:msg.range.start.line+1, l:msg.range.start.character+1, 'lsp does not supply a description')]]
    call call(a:next, l:args)
  endfunction

  let l:lsp = s:lspfactory.get()
  let l:state = s:newHandlerState()
  let l:msg = go#lsp#message#TypeDefinition(fnamemodify(a:fname, ':p'), a:line, a:col)
  call l:lsp.sendMessage(l:msg, funcref('s:typeDefinitionHandler', [function(a:handler, [], l:state)], l:state))
endfunction

" restore Vi compatibility settings
let &cpo = s:cpo_save
unlet s:cpo_save

" vim: sw=2 ts=2 et

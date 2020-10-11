" don't spam the user when Vim is started in Vi compatibility mode
let s:cpo_save = &cpo
set cpo&vim

scriptencoding utf-8

let s:mapargs = {}

function! go#debug_mode#InitMode(...) abort
  if a:0 == 0
    return
  endif

  let l:debug_mappings = go#config#DebugMappings()
  let s:mapargs = {}

  for l:arg in a:000
    if !has_key(l:debug_mappings, l:arg)
      continue
    endif

    let l:config = l:debug_mappings[l:arg]

    " do not attempt to apply the mapping when the value is an empty list.
    if len(l:config) == 0
      continue
    endif

    let l:lhs = l:config[0]
    try
      call execute(printf('autocmd FileType go call s:save_maparg_for(expand(''%%''), ''%s'')', l:lhs))

      let l:mapping = printf('autocmd FileType go nmap <buffer> %s', l:lhs)
      if len(l:config) > 1
        let l:mapping = printf('%s %s', l:mapping, l:config[1])
      endif
      let l:mapping = printf('%s <Plug>%s', l:mapping, l:arg)
      call execute(l:mapping)
    catch
      call go#util#EchoError(printf('could not configure mapping for %s: %s', l:lhs, v:exception))
    endtry
  endfor
endfunction

function! s:save_maparg_for(bufname, lhs) abort
  " make sure bufname is the active buffer.
  if fnamemodify(a:bufname, ':p') isnot expand('%:p')
    call go#util#EchoWarning('buffer must be active to save its mappings')
    return
  endif

  " only normal-mode buffer-local mappings are needed, because all
  " vim-go-debug mappings are normal-mode buffer-local mappings. Therefore,
  " we only need to retrieve normal mode mappings that need to be saved.
  let l:maparg = maparg(a:lhs, 'n', 0, 1)
  if empty(l:maparg)
    return
  endif

  if l:maparg.buffer
    let l:bufmapargs = get(s:mapargs, a:bufname, [])
    let l:bufmapargs = add(l:bufmapargs, l:maparg)
    let s:mapargs[a:bufname] = l:bufmapargs
  endif
endfunction

function! go#debug_mode#Restore() abort
  call s:restoremappingfor(bufname(''))
endfunction

function! s:restoremappingfor(bufname) abort
  if !has_key(s:mapargs, a:bufname)
    return
  endif

  for l:maparg in s:mapargs[a:bufname]
    let l:mapping = s:restore_mapping(l:maparg)
  endfor
  call remove(s:mapargs, a:bufname)
endfunction

function! s:restore_mapping(maparg)
  if empty(a:maparg)
    return
  endif
  if !exists('*mapset')
    " see :h :map-arguments
    let l:silent_attr = get(a:maparg, 'silent',  0) ? '<silent>' : ''
    let l:nowait_attr = get(a:maparg, 'no_wait', 0) ? '<nowait>' : ''
    let l:buffer_attr = get(a:maparg, 'buffer',  0) ? '<buffer>' : ''
    let l:expr_attr   = get(a:maparg, 'expr',    0) ? '<expr>'   : ''
    let l:unique_attr = get(a:maparg, 'unique',  0) ? '<unique>' : ''
    let l:script_attr = get(a:maparg, 'script',  0) ? '<script>' : ''

    let l:command     = [a:maparg['mode'], (get(a:maparg, 'noremap', 0) ? 'nore' : ''), 'map']
    let l:command     = join(filter(l:command, '!empty(v:val)'), '')
    let l:rhs         = a:maparg['rhs']
    let l:lhs         = a:maparg['lhs']

    " NOTE: most likely <buffer> should be first
    let l:mapping = join(filter([l:command, l:buffer_attr, l:silent_attr, l:nowait_attr, l:expr_attr, l:unique_attr, l:script_attr, l:lhs, l:rhs], '!empty(v:val)'))
    call execute(l:mapping)
    return
  endif

  call mapset('n', 0, a:maparg)
  return
endfunction

" vim: sw=2 ts=2 et

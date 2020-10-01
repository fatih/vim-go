" vim: sw=2 ts=2

" The idea of this file is to provide a 'debug vim mode' 
" as in vim's normal or insert mode, which allows the user to have key mappings
" only when vim-go's debugger is active.
"
" This is done by saving the user mappings as of the time of the `Start`
" and restoring them during the `Stop`
"
" Example user defined mappings:
"
" let g:go_debug_mappings = [
"   \['nmap <nowait>',  'c', '<Plug>(go-debug-continue)'],
"   \['nmap',           'q', ':ExtendedGoDebugStop<CR>'],
"   \['nmap <nowait>',  'n', '<Plug>(go-debug-next)'],
"   \['nmap',           's', '<Plug>(go-debug-step)'],
" \]

" let s:default_mappings = [
"   \["nmap", "<F5>",  "<Plug>(go-debug-continue)"],
"   \["nmap", "<F6>",  "<Plug>(go-debug-print)"],
"   \["nmap", "<F9>",  "<Plug>(go-debug-breakpoint)"],
"   \["nmap", "<F10>", "<Plug>(go-debug-next)"],
"   \["nmap", "<F11>", "<Plug>(go-debug-step)"],
" \]

function! go#debug_mode#InitMode(default_mappings) abort
  " converts the a:default_mappings and g:go_debug_mappings (user specified mappings)
  " to appropriate formats for merging of the mappings.

  " The need for merge of the mappings is performed in order to fill potential gaps
  " in the user specified mappings. For example, if the user didn't set up
  " a mapping for <Plug>(go-debug-continue) the one in a:default_mappings
  " will be used.
  "
  " After the merge a save of the user's mappings is performed, e.g. if the
  " user remapped 'c' to <Plug>(go-debug-continue), the original meaning of
  " 'c' will be saved. That is done so it can be restored at the Stop() call

  " User mappings are not limited to <Plug>(go*) rhs's (see h: rhs), anything could be mapped
  " and the user could have more that one mapping for a particular <Plug>(go*) rhs

  " {'F10': '<Plug>(go-debug-next)', '<F11>': '<Plug>(go-debug-step)'}
  let lhs_to_rhs_defaults      = s:list_to_dict(map(deepcopy(a:default_mappings),  'v:val[1:]'))
  " {'c': 'nmap <nowait>', 'F10': 'nnoremap'}
  let lhs_to_map_cmd_defaults  = s:list_to_dict(map(deepcopy(a:default_mappings),  'reverse(v:val[:1])'))

  let user_mappings = get(g:, 'go_debug_mappings', [])
  let lhs_to_rhs_user = s:list_to_dict(map(deepcopy(user_mappings), 'v:val[1:]'))
  let lhs_to_map_cmd_user = s:list_to_dict(map(deepcopy(user_mappings),  'reverse(v:val[:1])'))

  " The first reverse_dict will return a Dict with rhs as key and List of lhs's,
  " because there may be more than one lhs that maps to a rhs.
  " Then a union of the mappings is performed by extend and the user's mappings take precedence
  let l:merged_rhs_to_lhss = extend(s:reverse_dict(lhs_to_rhs_defaults), s:reverse_dict(lhs_to_rhs_user), 'force')
  let l:merged_lhs_to_map_cmd = extend(lhs_to_map_cmd_defaults, lhs_to_map_cmd_user, 'force')
  let s:mappings_save = {}

  for [rhs, lhss] in items(l:merged_rhs_to_lhss)
    for lhs in lhss
      let s:mappings_save[lhs] = maparg(lhs, '', 0, 1)
      let command = join([l:merged_lhs_to_map_cmd[lhs], lhs, rhs])
      execute command
    endfor
  endfor
endfunction

function! go#debug_mode#Restore(...) abort
  for [lhs, save] in items(s:mappings_save)
    let command = s:restore_mapping(lhs, save)
    silent! execute command
  endfor
endfunction

function! s:restore_mapping(lhs, maparg_save)
  " Restores or unmaps the lhs if maparg_save is empty()

  " example maparg result if the mapping exists; see :h maparg()
  " {
  "   'silent': 0,
  "   'noremap': 1,
  "   'lhs': '<Space>n', " NOTE: leader is replaced with the mapleader var 
  "   'mode': 'n',
  "   'nowait': 0,
  "   'expr': 0,
  "   'sid': 2,
  "   'rhs': ':tabnew<CR>',
  "   'buffer': 0
  " }

  let post_maparg = maparg(a:lhs, '', 0, 1)
  if empty(a:maparg_save) " see :h :unmap
    let buffer_attr = get(post_maparg, 'buffer',  0) ? '<buffer>' : ''
    let command = [post_maparg['mode'], 'unmap', buffer_attr, ' ', a:lhs]
    let command = join(filter(command, '!empty(v:val)'), '')

    return command
  endif

  " see :h :map-arguments
  let silent_attr = get(a:maparg_save, 'silent',  0) ? '<silent>' : ''
  let nowait_attr = get(a:maparg_save, 'no_wait', 0) ? '<nowait>' : ''
  let buffer_attr = get(a:maparg_save, 'buffer',  0) ? '<buffer>' : ''
  let expr_attr   = get(a:maparg_save, 'expr',    0) ? '<expr>'   : ''
  let unique_attr = get(a:maparg_save, 'unique',  0) ? '<unique>' : ''
  let script_attr = get(a:maparg_save, 'script',  0) ? '<script>' : ''

  let command     = [a:maparg_save['mode'], (get(a:maparg_save, 'noremap', 0) ? 'nore' : ''), 'map']
  let command     = join(filter(command, '!empty(v:val)'), '')
  let rhs         = a:maparg_save['rhs']

  " NOTE: most likely <buffer> should be first
  return join(filter([command, buffer_attr, silent_attr, nowait_attr, expr_attr, unique_attr, script_attr, a:lhs, rhs], '!empty(v:val)'))
endfunction

function! s:reverse_dict(d)
  let l:res = {}

  for [key, value] in items(a:d)
    if has_key(l:res, value)
      let l:res[value] = add(l:res[value], key)
    else
      let l:res[value] = [key]
    endif
  endfor

  return l:res
endfunction

function! s:list_to_dict(l)
  let l:res = {}
  for [key, val] in a:l
    let l:res[key] = val
  endfor
  return l:res
endfunction

" Statusline
""""""""""""""""""""""""""""""""

" s:statuses is a global reference to all statuses. It stores the job per import path
" current stored status dict is in form:
" { 
"   'desc'  : 'Job description',
"   'state' : 'Job state, such as success, failure, etc..',
"   'type'  : 'Job type, such as build, test, etc..'
" }
let s:statuses = {}

" Show returns the current status of the job. It displays it in form of
"   desc: [type|state]
function! go#statusline#Show() abort
  if empty(s:statuses)
    return '**NOTIMPLEMENTED**'
  endif

  let import_path =  go#package#ImportPath(expand('%:p:h'))

  if !has_key(s:statuses, import_path)
    return ''
  endif

  let status = s:statuses[import_path]
  if !has_key(status, 'desc') || !has_key(status, 'state') || !has_key(status, 'type')
    return ''
  endif

  return printf("%s: [%s|%s]", status.desc, status.type, status.state)
endfunction

" Update updates (adds) the statusline for the given import_path with the
" given status dict. It overrides any previously set status.
function! go#statusline#Update(import_path, status) abort
  let s:statuses[a:import_path] = a:status
endfunction

function! go#statusline#Clear() abort
  " TODO: invoke timer to clean up s:statuses in certain intervals to prevent
  " memory leak
endfunction

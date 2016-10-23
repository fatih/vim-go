" Statusline
""""""""""""""""""""""""""""""""

" s:statuses is a global reference to all statuses. It stores the job per import path.
" Current stored status dict is in form:
" { 
"   'desc'  : 'Job description',
"   'state' : 'Job state, such as success, failure, etc..',
"   'type'  : 'Job type, such as build, test, etc..'
" }
let s:statuses = {}

" timer_id for cleaner
let s:timer_id = 0

" Show returns the current status of the job for 20 seconds (configurable). It
" displays it in form of 'desc: [type|state]' if there is any state available,
" if not it returns an empty string.
function! go#statusline#Show() abort
  " lazy initialiation of the cleaner
  if !s:timer_id
    " clean every 20 seconds all statuses
    let interval = get(g:, 'go_statusline_duration', 20000)
    let s:timer_id = timer_start(interval, function('go#statusline#Clear'), {'repeat': -1})
  endif
  
  " nothing to show
  if empty(s:statuses)
    return ''
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

  " also reset the timer, so the user has time to see it in the statusline.
  " Setting the timer_id to 0 will trigger a new cleaner routine.
  call timer_stop(s:timer_id)
  let s:timer_id = 0
endfunction

" Clear clears all currently stored statusline data. The timer_id argument is
" just a placeholder so we can pass it to a timer_start() function if needed.
function! go#statusline#Clear(timer_id) abort
  let s:statuses = {}
endfunction

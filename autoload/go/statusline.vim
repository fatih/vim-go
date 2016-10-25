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

" last_text is the last generated text
let s:last_text = ""

" Show returns the current status of the job for 20 seconds (configurable). It
" displays it in form of 'desc: [type|state]' if there is any state available,
" if not it returns an empty string. This function should be plugged directly
" into the statusline.
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

  let text = printf("vim-go %s: [%s:%s]", status.desc, status.type, status.state)

  " only update highlight if status has changed.
  if text != s:last_text 
    if status.state == "success"
      hi goStatusLineColor cterm=bold ctermbg=76 ctermfg=22
    elseif status.state == "started"
      hi goStatusLineColor cterm=bold ctermbg=208 ctermfg=88
    elseif status.state == "failed"
      hi goStatusLineColor cterm=bold ctermbg=196 ctermfg=52
    endif
  endif

  let s:last_text = text
  return text
endfunction

" Update updates (adds) the statusline for the given import_path with the
" given status dict. It overrides any previously set status.
function! go#statusline#Update(import_path, status) abort
  let s:statuses[a:import_path] = a:status

  " force to update the statusline, otherwise the user needs to move the
  " cursor
  exe 'let &ro = &ro'


  " also reset the timer, so the user has time to see it in the statusline.
  " Setting the timer_id to 0 will trigger a new cleaner routine.
  call timer_stop(s:timer_id)
  let s:timer_id = 0
endfunction

" Clear clears all currently stored statusline data. The timer_id argument is
" just a placeholder so we can pass it to a timer_start() function if needed.
function! go#statusline#Clear(timer_id) abort
  let s:statuses = {}

  " force to update the statusline, otherwise the user needs to move the
  " cursor
  exe 'let &ro = &ro'
endfunction

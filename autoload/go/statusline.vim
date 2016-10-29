" Statusline
""""""""""""""""""""""""""""""""

" s:statuses is a global reference to all statuses. It stores the statuses per
" import paths (map[string][]status), where each status is unique per its
" type. Current status dict is in form:
" { 
"   'desc'        : 'Job description',
"   'state'       : 'Job state, such as success, failure, etc..',
"   'type'        : 'Job type, such as build, test, etc..'
"   'created_at'  : 'Time it was created as seconds since 1st Jan 1970'
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
    " clean every 10 seconds all statuses
    let interval = get(g:, 'go_statusline_duration', 10000)
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

  let statuses = s:statuses[import_path]

  let status_text = ''
  for status in statuses
    if !has_key(status, 'desc') || !has_key(status, 'state') || !has_key(status, 'type')
      return ''
    endif

    let text = printf("[%s|%s]", status.type, status.state)
    let status_text = text . status_text
  endfor

  if empty(status_text)
    return ''
  endif

  " only update highlight if status has changed.
  if status_text != s:last_text 
    if status.state == "success" || status.state == "finished"
      hi goStatusLineColor cterm=bold ctermbg=76 ctermfg=22
    elseif status.state == "started" || status.state == "analysing"
      hi goStatusLineColor cterm=bold ctermbg=208 ctermfg=88
    elseif status.state == "failed"
      hi goStatusLineColor cterm=bold ctermbg=196 ctermfg=52
    endif
  endif

  let s:last_text = status_text
  return status_text
endfunction

" Update updates (adds) the statusline for the given import_path with the
" given status dict. It overrides any previously set status.
function! go#statusline#Update(import_path, status) abort
  call s:add_status(a:import_path, a:status)

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
  for [import_path, statuses] in items(s:statuses)
      " if there is just one status, remove it entirely
      if len(statuses) == 1
        call remove(s:statuses, import_path)
        continue
      endif
        
      " if we have multiple status items for a given pkg, remove only 20
      " seconds old ones
	    let index = 0
      for status in statuses 
        let elapsed_time = reltimestr(reltime(status.created_at))

        "strip whitespace
        let elapsed_time = substitute(elapsed_time, '^\s*\(.\{-}\)\s*$', '\1', '')
        if str2nr(elapsed_time) > 10
          call remove(statuses, index)
        endif

        let index += 1
      endfor

      let s:statuses[import_path] = statuses
  endfor

  if len(s:statuses) == 0
    let s:statuses = {}
  endif

  " force to update the statusline, otherwise the user needs to move the
  " cursor
  exe 'let &ro = &ro'
endfunction

" add_status adds the given status for the given import_path. It appends the
" status if there are more than one status. If there is already a status with
" the same status type, the given status will be overriden.
function! s:add_status(import_path, status)
  let a:status.created_at = reltime()

  " there are no statuses for the given import_path, creat the first 
  if !has_key(s:statuses, a:import_path)
    let s:statuses[a:import_path] = [a:status]
    return
  endif

  " there are some statuses for the given import_path, thus search for an
  " existing status, if one exists override it. If there is none, it means we
  " have a new status that we want to append to the statuses list
  let pkg_statuses = s:statuses[a:import_path]

  let found = 0
	let index = 0
  for status in pkg_statuses
    if status.type == a:status.type
      let found = 1

      " override it
      let pkg_statuses[index] = a:status
    endif

	  let index += 1
  endfor

  " append the existing status
  if !found
    call add(pkg_statuses, a:status)
  endif

  let s:statuses[a:import_path] = pkg_statuses
endfunction

" vim: sw=2 ts=2 et

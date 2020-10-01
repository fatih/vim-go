" don't spam the user when Vim is started in Vi compatibility mode
let s:cpo_save = &cpo
set cpo&vim

function! Test_GoDebugModeRemapsKeysAndRestoresThem() abort
  if !go#util#has_job()
    return
  endif

  try
    let g:go_debug_mappings = [['nmap <nowait>',  'q', '<Plug>(go-debug-continue)']]
    let l:tmp = gotest#load_fixture('debug/debugmain/debugmain.go')

    call assert_false(exists(':GoDebugStop'))

    let l:cd = exists('*haslocaldir') && haslocaldir() ? 'lcd' : 'cd'
    execute l:cd . ' debug/debugmain'

    call go#debug#Start('debug')

    let l:start = reltime()
    while maparg('q') == '' && reltimefloat(reltime(l:start)) < 10
      sleep 100m
    endwhile

    call assert_false(exists(':GoDebugStart'))
    call assert_equal('<Plug>(go-debug-continue)', maparg('q'))

    call go#debug#Stop()
    while exists(':GoDebugStop') && reltimefloat(reltime(l:start)) < 10
      sleep 100m
    endwhile
    call assert_equal('', maparg('q'))
  finally
    call delete(l:tmp, 'rf')
  endtry
endfunction

" restore Vi compatibility settings
let &cpo = s:cpo_save
unlet s:cpo_save

" vim: sw=2 ts=2 et

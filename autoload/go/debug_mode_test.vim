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

" s:debug takes 2 optional arguments. The first is a package to debug. The
" second is a flag to indicate whether to reset GOPATH after
" gotest#load_fixture is called in order to test behavior outside of GOPATH.
function! s:debug(...) abort
  if !go#util#has_job()
    return
  endif

  try
    let $oldgopath = $GOPATH
    let l:tmp = gotest#load_fixture('debug/debugmain/debugmain.go')

    if a:0 > 1 && a:2 == 1
      let $GOPATH = $oldgopath
    endif

    call go#debug#Breakpoint(6)

    call assert_false(exists(':GoDebugStop'))

    if a:0 == 0
      let l:cd = exists('*haslocaldir') && haslocaldir() ? 'lcd' : 'cd'
      execute l:cd . ' debug/debugmain'
      let l:job = go#debug#Start('debug')
    else
      let l:job = go#debug#Start('debug', a:1)
    endif

    let l:start = reltime()
    while !exists(':GoDebugStop') && reltimefloat(reltime(l:start)) < 10
      sleep 100m
    endwhile

    call assert_true(exists(':GoDebugStop'))
    call gotest#assert_quickfix(getqflist(), [])

    call go#debug#Stop()

    if !has('nvim')
      call assert_equal(job_status(l:job), 'dead')
    endif

    call assert_false(exists(':GoDebugStop'))

  finally
    call go#debug#Breakpoint(6)
    call delete(l:tmp, 'rf')
  endtry
endfunction

" restore Vi compatibility settings
let &cpo = s:cpo_save
unlet s:cpo_save

" vim: sw=2 ts=2 et

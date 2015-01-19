"Check if has vimproc
function! go#has_vimproc()
    if !exists('g:vimgo#use_vimproc')
    try
      call vimproc#version()
      let exists_vimproc = 1
    catch
      let exists_vimproc = 0
    endtry

    let g:vimgo#use_vimproc = exists_vimproc
  endif

  return g:vimgo#use_vimproc
endfunction

" vim:ts=4:sw=4:et

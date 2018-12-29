" don't spam the user when Vim is started in Vi compatibility mode
let s:cpo_save = &cpo
set cpo&vim

function! go#auto#template_autocreate()
  " create new template from scratch
  if get(g:, "go_template_autocreate", 1) && &modifiable
    call go#template#create()
  endif
endfunction

function! go#auto#echo_go_info()
  if !get(g:, "go_echo_go_info", 1)
    return
  endif

  if !exists('v:completed_item') || empty(v:completed_item)
    return
  endif
  let item = v:completed_item

  if !has_key(item, "info")
    return
  endif

  if empty(item.info)
    return
  endif

  redraws! | echo "vim-go: " | echohl Function | echon item.info | echohl None
endfunction

function! go#auto#auto_type_info()
  " GoInfo automatic update
  if get(g:, "go_auto_type_info", 0)
    call go#tool#Info(0)
  endif
endfunction

function! go#auto#auto_sameids()
  " GoSameId automatic update
  if get(g:, "go_auto_sameids", 0)
    call go#guru#SameIds(0)
  endif
endfunction

function! go#auto#fmt_autosave()
  " Go code formatting on save
  if get(g:, "go_fmt_autosave", 1)
    call go#fmt#Format(-1)
  endif
endfunction

function! go#auto#metalinter_autosave()
  " run gometalinter on save
  if get(g:, "go_metalinter_autosave", 0)
    call go#lint#Gometa(0, 1)
  endif
endfunction

function! go#auto#modfmt_autosave()
  " go.mod code formatting on save
  if get(g:, "go_mod_fmt_autosave", 1)
    call go#mod#Format()
  endif
endfunction

function! go#auto#asmfmt_autosave()
  " Go asm formatting on save
  if get(g:, "go_asmfmt_autosave", 0)
    call go#asmfmt#Format()
  endif
endfunction

" restore Vi compatibility settings
let &cpo = s:cpo_save
unlet s:cpo_save

" vim: sw=2 ts=2 et

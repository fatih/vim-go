if exists("g:go_loaded_gotools")
    finish
endif
let g:go_loaded_gotools = 1


if !hasmapto('<Plug>(go-run)')
    nnoremap <silent> <Plug>(go-run) :<C-u>call go#command#Run(expand('%'))<CR>
endif

if !hasmapto('<Plug>(go-build)')
    nnoremap <silent> <Plug>(go-build) :<C-u>call go#command#Build('')<CR>
endif

if !hasmapto('<Plug>(go-install)')
    nnoremap <silent> <Plug>(go-install) :<C-u>call go#command#Install()<CR>
endif

if !hasmapto('<Plug>(go-test)')
    nnoremap <silent> <Plug>(go-test) :<C-u>call go#command#Test()<CR>
endif

if !hasmapto('<Plug>(go-vet)')
    nnoremap <silent> <Plug>(go-vet) :<C-u>call go#command#Vet()<CR>
endif

if !hasmapto('<Plug>(go-files)')
    nnoremap <silent> <Plug>(go-files) :<C-u>call go#tool#Files()<CR>
endif

if !hasmapto('<Plug>(go-deps)')
    nnoremap <silent> <Plug>(go-deps) :<C-u>call go#tool#Deps()<CR>
endif

if !hasmapto('<Plug>(go-info)')
    nnoremap <silent> <Plug>(go-info) :<C-u>call go#complete#Info()<CR>
endif

" This needs to be here, it doesn't get sourced when put into a file under ftplugin/go
if !hasmapto('<Plug>(go-import)')
    nnoremap <silent> <Plug>(go-import) :<C-u>call GoSwitchImport(1, '', expand('<cword>'))<CR>
endif


command! -nargs=0 GoFiles echo go#tool#Files()
command! -nargs=0 GoDeps echo go#tool#Deps()
command! -nargs=* GoInfo call go#complete#Info()

command! -nargs=* -range -bang GoRun call go#command#Run(<bang>0,<f-args>)
command! -nargs=? -range -bang GoBuild call go#command#Build(<bang>0)

command! -nargs=* GoInstall call go#command#Install(<f-args>)
command! -nargs=0 GoTest call go#command#Test()
command! -nargs=0 GoVet call go#command#Vet()

" vim:ts=4:sw=4:et

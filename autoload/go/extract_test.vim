" don't spam the user when Vim is started in Vi compatibility mode
let s:cpo_save = &cpo
set cpo&vim

func! Test_Extract() abort
  let l:wd = getcwd()
  try
    let l:tmp = gotest#write_file('a/a.go', [
          \ 'package a',
          \ '',
          \ 'func f(v int) {',
          \ '	for i := 0; i < v; i++ {',
          \ "		p\x1f" . 'rintln("outputting something")',
          \ '		println("i is ", i+1)',
          \ '	}',
          \ '}'])

    silent! execute "normal vj$\<Esc>"

    call go#extract#Extract(line('.'))

    let start = reltime()
    while &modified == 0 && reltimefloat(reltime(start)) < 10
      sleep 100m
    endwhile

    call gotest#assert_buffer(1, [
          \ 'func f(v int) {',
          \ '	for i := 0; i < v; i++ {',
          \ '		newFunction(i)',
          \ '	}',
          \ '}',
          \ '',
          \ 'func newFunction(i int) {',
          \ '	println("outputting something")',
          \ '	println("i is ", i+1)',
          \ '}'])

  finally
    call go#util#Chdir(l:wd)
    call delete(l:tmp, 'rf')
  endtry
endfunc

" restore Vi compatibility settings
let &cpo = s:cpo_save
unlet s:cpo_save

" vim: sw=2 ts=2 et

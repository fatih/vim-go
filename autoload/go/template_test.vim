" don't spam the user when Vim is started in Vi compatibility mode
let s:cpo_save = &cpo
set cpo&vim

func! Test_TemplateCreate() abort
  let g:go_gopls_enabled = 0
  let l:wd = getcwd()
  try
    let l:tmp = gotest#write_file('foo/empty.txt', [''])

    edit foo/bar.go

    call gotest#assert_buffer(1, [
          \ 'func main() {',
          \ '\tfmt.Println("vim-go")',
          \ '}'])
  finally
    call go#util#Chdir(l:wd)
    call delete(l:tmp, 'rf')
  endtry

  let l:wd = getcwd()
  try
    let l:tmp = gotest#write_file('foo/empty.txt', [''])
    edit foo/bar_test.go

    call gotest#assert_buffer(1, [
          \ 'func TestHelloWorld(t *testing.T) {',
          \ '\t// t.Fatal("not implemented")',
          \ '}'])
  finally
    call go#util#Chdir(l:wd)
    call delete(l:tmp, 'rf')
  endtry
endfunc

func! Test_TemplateCreate_UsePkg() abort
  let l:wd = getcwd()
  try
    let g:go_gopls_enabled = 0
    let l:tmp = gotest#write_file('foo/empty.txt', [''])

    let g:go_template_use_pkg = 1
    edit foo/bar.go

    call gotest#assert_buffer(0, ['package foo'])
  finally
    call go#util#Chdir(l:wd)
    call delete(l:tmp, 'rf')
  endtry
endfunc

func! Test_TemplateCreate_PackageExists() abort
  let l:wd = getcwd()
  try
    let g:go_gopls_enabled = 0
    let l:tmp = gotest#write_file('quux/quux.go', ['package foo'])

    edit quux/bar.go

    call gotest#assert_buffer(0, ['package foo'])
  finally
    call go#util#Chdir(l:wd)
    call delete(l:tmp, 'rf')
  endtry
endfunc

" restore Vi compatibility settings
let &cpo = s:cpo_save
unlet s:cpo_save

" vim: sw=2 ts=2 et

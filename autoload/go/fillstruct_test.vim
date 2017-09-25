func! Test_fillstruct() abort
  try
    let l:tmp = gotest#loadFile('a/a.go', [
          \ 'package a',
          \ 'import "net/mail"',
          \ 'var addr = mail.Address{}'])

    call go#fillstruct#FillStruct()
    call gotest#assert_buffer(1, [
          \ 'var addr = mail.Address{',
          \ '\tName:    "",',
          \ '\tAddress: "",',
          \ '}'])
  finally
    call delete(l:tmp, 'rf')
  endtry
endfunc

" vim: sw=2 ts=2 et

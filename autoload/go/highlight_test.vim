" don't spam the user when Vim is started in Vi compatibility mode
let s:cpo_save = &cpo
set cpo&vim

function! Test_gomodVersion_highlight() abort
  try
    syntax on

    let l:dir = gotest#write_file('gomodtest/go.mod', [
          \ 'module github.com/fatih/vim-go',
          \ '',
          \ '\x1frequire (',
          \ '\tversion/simple v1.0.0',
          \ '\tversion/simple-pre-release v1.0.0-rc',
          \ '\tversion/simple-pre-release v1.0.0+meta',
          \ '\tversion/simple-pre-release v1.0.0-rc+meta',
          \ '\tversion/pseudo/premajor v1.0.0-20060102150405-0123456789abcdef',
          \ '\tversion/pseudo/prerelease v1.0.0-prerelease.0.20060102150405-0123456789abcdef',
          \ '\tversion/pseudo/prepatch v1.0.1-0.20060102150405-0123456789abcdef',
          \ '\tversion/simple/incompatible v2.0.0+incompatible',
          \ '\tversion/pseudo/premajor/incompatible v2.0.0-20060102150405-0123456789abcdef+incompatible',
          \ '\tversion/pseudo/prerelease/incompatible v2.0.0-prerelease.0.20060102150405-0123456789abcdef+incompatible',
          \ '\tversion/pseudo/prepatch/incompatible v2.0.1-0.20060102150405-0123456789abcdef+incompatible',
          \ ')'])

    let l:lineno = 4
    let l:lineclose = line('$')
    while l:lineno < l:lineclose
      let l:line = getline(l:lineno)
      let l:col = col([l:lineno, '$']) - 1
      let l:idx = len(l:line) - 1
      let l:from = stridx(l:line, ' ') + 1

      while l:idx >= l:from
        call cursor(l:lineno, l:col)
        let l:synname = synIDattr(synID(l:lineno, l:col, 1), 'name')
        let l:errlen = len(v:errors)

        call assert_equal('gomodVersion', l:synname, 'version on line ' . l:lineno)

        " continue at the next line if there was an error at this column;
        " there's no need to test each column once an error is detected.
        if l:errlen < len(v:errors)
          break
        endif

        let l:col -= 1
        let l:idx -= 1
      endwhile
      let l:lineno += 1
    endwhile
  finally
    call delete(l:dir, 'rf')
  endtry
endfunc

function! Test_gomodVersion_incompatible_highlight() abort
  try
    syntax on

    let l:dir = gotest#write_file('gomodtest/go.mod', [
          \ 'module github.com/fatih/vim-go',
          \ '',
          \ '\x1frequire (',
          \ '\tversion/invalid/premajor/incompatible v1.0.0-20060102150405-0123456789abcdef+incompatible',
          \ '\tversion/invalid/prerelease/incompatible v1.0.0-prerelease.0.20060102150405-0123456789abcdef+incompatible',
          \ '\tversion/invalid/prepatch/incompatible v1.0.1-0.20060102150405-0123456789abcdef+incompatible',
          \ ')'])

    let l:lineno = 4
    let l:lineclose = line('$')
    while l:lineno < l:lineclose
      let l:line = getline(l:lineno)
      let l:col = col([l:lineno, '$']) - 1
      let l:idx = len(l:line) - 1
      let l:from = stridx(l:line, '+')

      while l:idx >= l:from
        call cursor(l:lineno, l:col)
        let l:synname = synIDattr(synID(l:lineno, l:col, 1), 'name')
        let l:errlen = len(v:errors)

        call assert_notequal('gomodVersion', l:synname, 'version on line ' . l:lineno)

        " continue at the next line if there was an error at this column;
        " there's no need to test each column once an error is detected.
        if l:errlen < len(v:errors)
          break
        endif

        let l:col -= 1
        let l:idx -= 1
      endwhile
      let l:lineno += 1
    endwhile
  finally
    call delete(l:dir, 'rf')
  endtry
endfunc

function! Test_numeric_literal_highlight() abort
  syntax on

  let tests = {
        \ 'lone zero': {'group': 'goDecimalInt', 'value': '0'},
        \ 'integer': {'group': 'goDecimalInt', 'value': '1234567890'},
        \ 'integerGrouped': {'group': 'goDecimalInt', 'value': '1_234_567_890'},
        \ 'integerErrorLeadingUnderscore': {'group': 'goDecimalError', 'value': '_1234_567_890'},
        \ 'integerErrorTrailingUnderscore': {'group': 'goDecimalError', 'value': '1_234_567890_'},
        \ 'integerErrorDoubleUnderscore': {'group': 'goDecimalError', 'value': '1_234__567_890'},
        \ 'hexadecimal': {'group': 'goHexadecimalInt', 'value': '0x0123456789abdef'},
        \ 'hexadecimalGrouped': {'group': 'goHexadecimalInt', 'value': '0x012_345_678_9ab_def'},
        \ 'hexadecimalErrorLeading': {'group': 'goHexadecimalError', 'value': '0xg0123456789abdef'},
        \ 'hexadecimalErrorTrailing': {'group': 'goHexadecimalError', 'value': '0x0123456789abdefg'},
        \ 'hexadecimalErrorDoubleUnderscore': {'group': 'goHexadecimalError', 'value': '0x__0123456789abdef'},
        \ 'hexadecimalErrorTrailingUnderscore': {'group': 'goHexadecimalError', 'value': '0x0123456789abdef_'},
        \ 'heXadecimal': {'group': 'goHexadecimalInt', 'value': '0X0123456789abdef'},
        \ 'heXadecimalErrorLeading': {'group': 'goHexadecimalError', 'value': '0Xg0123456789abdef'},
        \ 'heXadecimalErrorTrailing': {'group': 'goHexadecimalError', 'value': '0X0123456789abdefg'},
        \ 'octal': {'group': 'goOctalInt', 'value': '01234567'},
        \ 'octalPrefix': {'group': 'goOctalInt', 'value': '0o1234567'},
        \ 'octalGrouped': {'group': 'goOctalInt', 'value': '0o1_234_567'},
        \ 'octalErrorLeading': {'group': 'goOctalError', 'value': '081234567'},
        \ 'octalErrorTrailing': {'group': 'goOctalError', 'value': '012345678'},
        \ 'octalErrorDoubleUnderscore': {'group': 'goOctalError', 'value': '0o__1234567'},
        \ 'octalErrorTrailingUnderscore': {'group': 'goOctalError', 'value': '0o_123456_7_'},
        \ 'octalErrorTrailingO': {'group': 'goOctalError', 'value': '0o_123456_7o'},
        \ 'octalErrorTrailingX': {'group': 'goOctalError', 'value': '0o_123456_7x'},
        \ 'octalErrorTrailingB': {'group': 'goOctalError', 'value': '0o_123456_7b'},
        \ 'OctalPrefix': {'group': 'goOctalInt', 'value': '0O1234567'},
        \ 'binaryInt': {'group': 'goBinaryInt', 'value': '0b0101'},
        \ 'binaryIntGrouped': {'group': 'goBinaryInt', 'value': '0b_01_01'},
        \ 'binaryErrorLeading': {'group': 'goBinaryError', 'value': '0b20101'},
        \ 'binaryErrorTrailing': {'group': 'goBinaryError', 'value': '0b01012'},
        \ 'binaryErrorDoubleUnderscore': {'group': 'goBinaryError', 'value': '0b_01__01'},
        \ 'binaryOverrideOctal': {'group': 'goBinaryError', 'value': '0b1234567'},
        \ 'binaryErrorTrailingUnderscore': {'group': 'goBinaryError', 'value': '0b_01_01_'},
        \ 'BinaryInt': {'group': 'goBinaryInt', 'value': '0B0101'},
        \ 'BinaryErrorLeading': {'group': 'goBinaryError', 'value': '0B20101'},
        \ 'BinaryErrorTrailing': {'group': 'goBinaryError', 'value': '0B01012'},
        \ }

  for kv in items(tests)
    let l:actual = s:numericHighlightGroupInAssignment(kv[0], kv[1].value)
    call assert_equal(kv[1].group, l:actual, kv[0])
  endfor
endfunction

function! Test_zero_as_index_element() abort
  syntax on

  let l:actual = s:numericHighlightGroupInSliceElement('zero-element', '0')
  call assert_equal('goDecimalInt', l:actual)
  let l:actual = s:numericHighlightGroupInMultidimensionalSliceElement('zero-element', '0')
  call assert_equal('goDecimalInt', l:actual, 'multi-dimensional')
endfunction

function! Test_zero_as_slice_index() abort
  syntax on

  let l:actual = s:numericHighlightGroupInSliceIndex('zero-index', '0')
  call assert_equal('goDecimalInt', l:actual)
  let l:actual = s:numericHighlightGroupInMultidimensionalSliceIndex('zero-index', '0', '0')

  call assert_equal('goDecimalInt', l:actual, 'multi-dimensional')
endfunction

function! Test_zero_as_start_slicing_slice() abort
  syntax on

  let l:actual = s:numericHighlightGroupInSliceSlicing('slice-slicing', '0', '1')
  call assert_equal('goDecimalInt', l:actual)
endfunction

function! s:numericHighlightGroupInAssignment(testname, value)
  let l:dir = gotest#write_file(printf('numeric/%s.go', a:testname), [
        \ 'package numeric',
        \ '',
        \ printf("var v = %s\x1f", a:value),
        \ ])

  try
    let l:pos = getcurpos()
    let l:actual = synIDattr(synID(l:pos[1], l:pos[2], 1), 'name')
    return l:actual
  finally
    call delete(l:dir, 'rf')
  endtry
endfunction

function! s:numericHighlightGroupInSliceElement(testname, value)
  let l:dir = gotest#write_file(printf('numeric/slice-element/%s.go', a:testname), [
        \ 'package numeric',
        \ '',
        \ printf("v := []int{\x1f%s}", a:value),
        \ ])

  try
    let l:pos = getcurpos()
    let l:actual = synIDattr(synID(l:pos[1], l:pos[2], 1), 'name')
    return l:actual
  finally
    call delete(l:dir, 'rf')
  endtry
endfunction

function! s:numericHighlightGroupInMultidimensionalSliceElement(testname, value)
  let l:dir = gotest#write_file(printf('numeric/slice-multidimensional-element/%s.go', a:testname), [
        \ 'package numeric',
        \ '',
        \ printf("v := [][]int{{\x1f%s},{%s}}", a:value, a:value),
        \ ])

  try
    let l:pos = getcurpos()
    let l:actual = synIDattr(synID(l:pos[1], l:pos[2], 1), 'name')
    return l:actual
  finally
    call delete(l:dir, 'rf')
  endtry
endfunction

function! s:numericHighlightGroupInSliceIndex(testname, value)
  let l:dir = gotest#write_file(printf('numeric/slice-index/%s.go', a:testname), [
        \ 'package numeric',
        \ '',
        \ 'var sl []int',
        \ printf("println(sl[\x1f%s])", a:value),
        \ ])

  try
    let l:pos = getcurpos()
    let l:actual = synIDattr(synID(l:pos[1], l:pos[2], 1), 'name')
    return l:actual
  finally
    call delete(l:dir, 'rf')
  endtry
endfunction

function! s:numericHighlightGroupInMultidimensionalSliceIndex(testname, first, second)
  let l:dir = gotest#write_file(printf('numeric/slice-multidimensional-index/%s.go', a:testname), [
        \ 'package numeric',
        \ '',
        \ 'var sl [][]int',
        \ printf("println(sl[\x1f%s][%s])", a:first, a:second),
        \ ])

  try
    let l:pos = getcurpos()
    let l:actual = synIDattr(synID(l:pos[1], l:pos[2], 1), 'name')
    return l:actual
  finally
    call delete(l:dir, 'rf')
  endtry
endfunction

function! s:numericHighlightGroupInSliceSlicing(testname, from, to)
  let l:dir = gotest#write_file(printf('numeric/slice-slicing/%s.go', a:testname), [
        \ 'package numeric',
        \ '',
        \ 'var sl = []int{1,2}',
        \ printf("println(sl[\x1f%s:%s])", a:from, a:to),
        \ ])
  try
    let l:pos = getcurpos()
    let l:actual = synIDattr(synID(l:pos[1], l:pos[2], 1), 'name')
    return l:actual
  finally
    call delete(l:dir, 'rf')
  endtry
endfunction

" restore Vi compatibility settings
let &cpo = s:cpo_save
unlet s:cpo_save

" vim: sw=2 ts=2 et

func! Test_add_tags() abort
  try
    let l:tmp = gotest#loadFile('a/a.go', [
          \ 'package main',
          \ '',
          \ 'type Server struct {',
          \ '    Name          string',
          \ '    ID            int',
          \ '    MyHomeAddress string',
          \ '    SubDomains    []string',
          \ '    Empty         string',
          \ '    Example       int64',
          \ '    Example2      string',
          \ '    Bar           struct {',
          \ '        Four string',
          \ '        Five string',
          \ '    }',
          \ '    Lala interface{}',
          \ '}'])

    silent call go#tags#run(0, 0, 40, "add", bufname(''), 1)
    call gotest#assert_buffer(0, [
          \ 'package main',
          \ '',
          \ 'type Server struct {',
          \ '    Name          string   `json:"name"`',
          \ '    ID            int      `json:"id"`',
          \ '    MyHomeAddress string   `json:"my_home_address"`',
          \ '    SubDomains    []string `json:"sub_domains"`',
          \ '    Empty         string   `json:"empty"`',
          \ '    Example       int64    `json:"example"`',
          \ '    Example2      string   `json:"example_2"`',
          \ '    Bar           struct {',
          \ '        Four string `json:"four"`',
          \ '        Five string `json:"five"`',
          \ '    } `json:"bar"`',
          \ '    Lala interface{} `json:"lala"`',
          \ '}'])
  finally
    call delete(l:tmp, 'rf')
  endtry
endfunc


func! Test_remove_tags() abort
  try
    let l:tmp = gotest#loadFile('a/a.go', [
      \ 'package main',
      \ '',
      \ 'type Server struct {',
      \ '  Name          string   `json:"name"`',
      \ '  ID            int      `json:"id"`',
      \ '  MyHomeAddress string   `json:"my_home_address"`',
      \ '  SubDomains    []string `json:"sub_domains"`',
      \ '  Empty         string   `json:"empty"`',
      \ '  Example       int64    `json:"example"`',
      \ '  Example2      string   `json:"example_2"`',
      \ '  Bar           struct {',
      \ '    Four string `json:"four"`',
      \ '    Five string `json:"five"`',
      \ '  } `json:"bar"`',
      \ '  Lala interface{} `json:"lala"`',
      \ '}'])

    silent call go#tags#run(0, 0, 40, "remove", bufname(''), 1)
    call gotest#assert_buffer(0, [
      \ 'package main',
      \ '',
      \ 'type Server struct {',
      \ '  Name          string',
      \ '  ID            int',
      \ '  MyHomeAddress string',
      \ '  SubDomains    []string',
      \ '  Empty         string',
      \ '  Example       int64',
      \ '  Example2      string',
      \ '  Bar           struct {',
      \ '    Four string',
      \ '    Five string',
      \ '  }',
      \ '  Lala interface{}',
      \ '}'])

  finally
    call delete(l:tmp, 'rf')
  endtry
endfunc

" vim:ts=2:sts=2:sw=2:et

if exists("g:go_loaded_oracle")
    finish
endif
let g:go_loaded_oracle = 1

nnoremap <silent> <Plug>(go-implements) :<C-u>call go#oracle#Implements(-1)<CR>

command! -range=% GoImplements call go#oracle#Implements(<count>)

command! -range=% GoOracleDescribe call go#oracle#Describe(<count>)
command! -range=% GoOracleCallees  call go#oracle#Callees(<count>)
command! -range=% GoOracleCallers call go#oracle#Callers(<count>)
command! -range=% GoOracleCallgraph call go#oracle#Callgraph(<count>)
command! -range=% GoOracleCallstack call go#oracle#Callstack(<count>)
command! -range=% GoOracleFreevars call go#oracle#Freevars(<count>)
command! -range=% GoOraclePeers call go#oracle#Peers(<count>)
command! -range=% GoOracleReferrers call go#oracle#Referrers(<count>)

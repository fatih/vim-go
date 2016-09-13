* cmd.vim: async :GoBuild
* cmd.vim: async :GoInstall
* cmd.vim: async :GoTest
* cmd.vim: async :GoTestCompile
* cmd.vim: async :GoRun. Output is put into a new buffer to. Enabled only if
  `let g:go_async_run = 1` is added. Doesn't work if the application waits for
  stdin. 

* coverage.vim: async :GoCoverage
* coverage.vim: async :GoCoverageBrowser
* def.vim: async :GoDef



FEATURES:

* cmd.vim: async :GoBuild.
* cmd.vim: async :GoInstall. 
* cmd.vim: async :GoTest
* cmd.vim: async :GoTestCompile
* cmd.vim: async :GoRun. Output is put into a new buffer to. Enabled only if
  `let g:go_async_run = 1` is added. Doesn't work if the application waits for
  stdin. 

* coverage.vim: async :GoCoverage
* coverage.vim: async :GoCoverageBrowser

* def.vim: async :GoDef (only if 'guru' is used)

* rename.vim: async :GoRename

* lint.vim: async :GoMetaLinter. Also works with the current autosave linting
  feature. As a reminder, to enable auto linting on save either call 
  `:GoMetaLinterAutoSaveToggle` (temporary) or add `let
  g:go_metalinter_autosave = 1` (persistent) to your virmc).

* doc.vim: :GoDocBrowser is now capable to to understand the identifier under
  the cursor (just like :GoDoc)

* guru.vim: All `guru` commands run asynchronously if Vim 8.0 is being used.
  Commands:
	* GoImplements
	* GoWhicherrs
	* GoCallees
	* GoDescribe
	* GoCallers
	* GoCallstack
	* GoFreevars
	* GoChannelPeers
	* GoReferrers

* :GoSameIds also runs asynchronously. This makes it useful especially for
  auto sameids mode. In this mode it constantly evaluates the identifier under the
  cursor whenever it's in hold position and then calls :GoSameIds. As a
  reminder, to enable auto info either call `:GoSameIdsAutoToggle`(temporary)
  or add `let g:go_auto_sameids = 1` (persistent) to your vimrc. 

* :GoInfo is now non blocking and works in async mode. This makes it useful
  especially for autoinfo mode. In this mode it constantly evaluates the
  identifier under the cursor whenever it's in hold position and then calls
  :GoInfo. As a reminder, to enable auto info either call
  `:GoAutoTypeInfoToggle`(temporary) or add `let g:go_auto_type_info = 1`
  (persistent) to your vimrc. 
  
  Second, it's now much more reliable due the usage of 'guru describe'.
  Previously it was using `gocode` which wouldn't return sufficient
  information. This makes it a little bit slower than `gocode` for certain Go
  code, but with time the speed of guru will improve.


BACKWARDS INCOMPATIBILITIES:

* remove vim-dispatch and vimproc.vim support. vim 8.0 has now the necessary
  API to invoke async jobs and timers. Going forward we should use those. Also
  this will remove the burden to maintain compatibility with those plugins.

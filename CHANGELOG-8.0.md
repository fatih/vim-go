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

* lint.vim: async :GoMetaLinter. Also works with the current autosave linting
  feature. As a reminder, to enable auto linting on save either call 
  `:GoMetaLinterAutoSaveToggle` (temporary) or add `let
  g:go_metalinter_autosave = 1` (persistent) to your virmc).

* doc.vim: :GoDocBrowser is now capable to to understand the identifier under
  the cursor

* guru.vim: All `guru` commands run asynchronously if Vim 8.0 is being used.
  Commands:
	* GoSameIds
	* GoImplements
	* GoWhicherrs
	* GoCallees
	* GoDescribe
	* GoCallers
	* GoCallstack
	* GoFreevars
	* GoChannelPeers
	* GoReferrers

BACKWARDS INCOMPATIBILITIES:

* remove vim-dispatch and vimproc.vim support. vim 8.0 has now the necessary
  API to invoke async jobs and timers. Going forward we should use those. Also
  this will remove the burden to maintain compatibility with those plugins.

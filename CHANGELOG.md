## 1.6 (unreleased)

FEATURES:

* New `CHANGELOG.md` file (which you're reading now). This will make it easier
  for me to track changes and release versions
* **`:GoCoverage`**: is now highlighting the current source file for
  covered/uncovered lines. If called again it clears the highlighting. This is
  a pretty good addition to vim-go and I suggest to check out the gif that shows
  it in action: https://twitter.com/fatih/status/716722650383564800 [gh-786]
* **`:GoCoverageBrowser`**: opens a new annotated HTML page. This is the old
  `:GoCoverage` behavior [gh-786]

IMPROVEMENTS:

* **`:GoCoverage`** is now executed async when used within Neovim [gh-686]

BUG FIXES:

* Term mode: fix closing location list if result is successful after a failed attempt [gh-768]
* Syntax: fix gotexttmpl identifier highlighting [gh-778]


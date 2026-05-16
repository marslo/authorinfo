## [2.1.1](https://github.com/marslo/authorinfo/compare/v2.1.0...v2.1.1) (2026-05-16)

### Others

* chore: add successful or failure message output, checked via `VerifyLastChange()`
  Signed-off-by: marslo <marslo.jiao@gmail.com>

## [2.1.0](https://github.com/marslo/authorinfo/compare/v2.0.0...v2.1.0) (2026-05-14)

### Features

* feat: creation timestamp will no be changed in update stage
  - refactored `s:UpdateAuthorInfo` to use buffer APIs (setline/append) instead of `normal` commands
  - fixed "File changed since reading it" warning in diff mode
  - optimized `system()` calls to only trigger on new file creation
  - added dynamic support for `g:vimrc_author` and `g:vimrc_email`
  
  Signed-off-by: marslo <marslo.jiao@gmail.com>

## [2.0.0](https://github.com/marslo/authorinfo/compare/v1.0.0...v2.0.0) (2026-05-14)

### ⚠ BREAKING CHANGES

* **refactor:** refactor the comment logic and creation timestamp for plugin

Signed-off-by: marslo <marslo.jiao@gmail.com>

### Features

* **refactor:** using `&commentstring` instead of plugin shortcuts for authorinfo comments ([5287e0b](https://github.com/marslo/authorinfo/commit/5287e0b4badee30a13543f991eb5787c8ce68012))

### Bug Fixes

* E121: Undefined variable: gotoLn ([bc2265a](https://github.com/marslo/authorinfo/commit/bc2265a2a572c0ea4afea6d4ab4e984e79889922))

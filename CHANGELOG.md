# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

--------------------------------------------------------------------------------

## [Unreleased]

### Added

- Add `cast` function to the registry
- Add `pair` function to the registry
- Add `OnAdd` piece hook
- Add `OnRemove` piece hook
- Add `key` function to library

### Changes

- Traits no longer run in a separated thread
- Revert `registry:include` accepting deep tables of queries
- Multiple pieces can be added in an entity in a single `registry:add` call
- Every data now is also a piece. This mean you can add pieces to datas

### Removed
- Function `merge` from library

### Fixes 

- Fix `registry:ask` return type being typed as `any`
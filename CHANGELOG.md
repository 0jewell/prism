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

### Changes

- Traits no longer run in a separated thread

### Removed
- Function `merge` from library

### Fixes 

- Fix `registry:ask` return type being typed as `any`
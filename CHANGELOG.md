# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

--------------------------------------------------------------------------------

## 0.2.0

### Added
- Added benchmark tests for entity insertion performance
- Added unit testing for archetype
- Added unit testing for queries
- Added `world:insert`
- Added `world:component`
- Added `world:delete` 

### Changes

- Moved `prism.Query` function to the world
- Changed registry module name to "world"
- Changed general syntax for creating queries
- Changed `registry:add` to `world:assign`
- Changed `registry:entity` to `world:spawn`
- Changed `registry:remove` to `world:remove`
- Changed `registry:contains` to `world:has`
- Changed `registry:delete` to `world:despawn`

--------------------------------------------------------------------------------

## 0.1.1

### Added

- Add `cast` function to the registry
- Add `pair` function to the registry
- Add `view` function to the registry
- Add `OnAdd` piece hook
- Add `OnRemove` piece hook
- Add `tag` function to library
- Add `tags` function to library
- Add `query.async` option to querySettings

### Changes

- Traits no longer run in a separated thread
- Revert `registry:include` accepting deep tables of queries
- Multiple pieces can be added in an entity in a single `registry:add` call
- Multiple pieces can be removed from an entity at a single `registry:remove` call
- Every data now is also a piece. This mean you can add pieces to datas

### Removed

- Function `merge` from library

### Fixes 

- Fix `registry:ask` return type being typed as `any`
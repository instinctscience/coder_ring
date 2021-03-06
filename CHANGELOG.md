# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.3] - 2022-01-12
### Changed
- Initial population is no longer done inside a transaction. For large base
  codes (base_length 4) initial population fails if a transaction is used.

## [0.2.2] - 2022-01-10
### Changed
- Changed initial population routine to use a stream. This seems to be much
  slower, but it avoids out of memory errors on the server.

## [0.2.1] - 2022-01-07
### Changed
- Fix issue when codes are excluded via expletive filter.

## [0.2.0] - 2021-04-16
### Changed
- Config app env location and setup changed slightly.

## [0.1.1] - 2021-04-16
### Changed
- Updated and added some docs.

## [0.1.0] - 2021-04-16
### Added
- Initial release

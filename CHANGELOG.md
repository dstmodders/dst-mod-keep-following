# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased][]

## [0.4.0][] - 2019-08-19

### Added

- Corresponding actions: `FOLLOW`, `PUSH`, `TENTFOLLOW` and `TENTPUSH`
- Support for disabled lag compensation

### Changed

- Follow and push behaviours to become separated
- Input handlers to be inside modmain

### Fixed

- Crash when lag compensation is being turned off

## [0.3.0][] - 2019-08-18

### Added

- Support for following/pushing a Tent sleeper
- Support for pushing

## [0.2.0][] - 2019-08-17

### Removed

- Leader reinitialization if a leader didn't change

### Fixed

- Delay after approaching a leader
- Delay before following a new leader

## 0.1.0 - 2019-08-15

First release.

[unreleased]: https://github.com/victorpopkov/dst-mod-keep-following/compare/v0.4.0...HEAD
[0.4.0]: https://github.com/victorpopkov/dst-mod-keep-following/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/victorpopkov/dst-mod-keep-following/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/victorpopkov/dst-mod-keep-following/compare/v0.1.0...v0.2.0

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased][]

### Added

- Support for following interruptions

### Fixed

- Client/Server position mismatch during interruptions
- Some movement issues when lag compensation is off

## [0.15.0][] - 2019-09-21

### Added

- Support for the following method configuration
- Support for the push mass checking configuration

### Changed

- Improved pathfinding precision

### Fixed

- Selection issue with ActionQueue Reborn

## [0.14.0][] - 2019-09-20

### Added

- Support for pushing players as a ghost

### Changed

- Improved compatibility with some other mods
- Improved debug output

### Removed

- Pending tasks in favour of custom threads

### Fixed

- Keeping the target distance behaviour

## [0.13.0][] - 2019-09-17

### Added

- Support for Balloon in all mobs mode

### Changed

- Improved clicking behaviour

### Removed

- Pushing support for Shadow Creatures

### Fixed

- Actions not showing on dedicated in all mobs mode
- Distance calculation between follower and leader

## [0.12.0][] - 2019-09-16

### Added

- Stopping on `CONTROL_ACTION`
- Support for all known mobs
- Support for mobs configuration

### Changed

- Configuration `pushing_lag_compensation` to `push_lag_compensation`

### Fixed

- Actions not showing in Woodie's Weregoose form
- Actions not showing when a player becomes a ghost

## [0.11.0][] - 2019-09-06

### Added

- Support for Beefalo/Baby Beefalo

### Fixed

- Action not showing when RMB pushing is enabled
- Behaviour when the leader doesn't exist anymore

## [0.10.0][] - 2019-09-05

### Changed

- Improved debug output
- Improved mod icon quality
- Improved pushing lag compensation behaviour

### Fixed

- Lag compensation state restoration after pushing

## [0.9.0][] - 2019-08-25

### Added

- Support for Balloon
- Support for pushing lag compensation
- Support for pushing with RMB

### Changed

- Improved debug output

## [0.8.0][] - 2019-08-23

### Added

- Support for more animals

### Changed

- Improved compatibility with some other mods
- Improved debug output
- Mod icon

## [0.7.0][] - 2019-08-22

### Added

- Support for Abigail and Big Bernie
- Support for Catcoon, Koalefant, Volt Goat and Mosling
- Support for stopping following/pushing on LMB click

## [0.6.0][] - 2019-08-20

### Added

- Support for Bunnymen
- Support for keeping the target distance configuration

### Changed

- Default action and push keys back to original
- Improved compatibility with some other mods

## [0.5.0][] - 2019-08-19

### Added

- Support for action and push keys configuration

### Changed

- Default action and push keys

### Fixed

- Crash when entering/leaving cave

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

[unreleased]: https://github.com/victorpopkov/dst-mod-keep-following/compare/v0.15.0...HEAD
[0.15.0]: https://github.com/victorpopkov/dst-mod-keep-following/compare/v0.14.0...v0.15.0
[0.14.0]: https://github.com/victorpopkov/dst-mod-keep-following/compare/v0.13.0...v0.14.0
[0.13.0]: https://github.com/victorpopkov/dst-mod-keep-following/compare/v0.12.0...v0.13.0
[0.12.0]: https://github.com/victorpopkov/dst-mod-keep-following/compare/v0.11.0...v0.12.0
[0.11.0]: https://github.com/victorpopkov/dst-mod-keep-following/compare/v0.10.0...v0.11.0
[0.10.0]: https://github.com/victorpopkov/dst-mod-keep-following/compare/v0.9.0...v0.10.0
[0.9.0]: https://github.com/victorpopkov/dst-mod-keep-following/compare/v0.8.0...v0.9.0
[0.8.0]: https://github.com/victorpopkov/dst-mod-keep-following/compare/v0.7.0...v0.8.0
[0.7.0]: https://github.com/victorpopkov/dst-mod-keep-following/compare/v0.6.0...v0.7.0
[0.6.0]: https://github.com/victorpopkov/dst-mod-keep-following/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/victorpopkov/dst-mod-keep-following/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/victorpopkov/dst-mod-keep-following/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/victorpopkov/dst-mod-keep-following/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/victorpopkov/dst-mod-keep-following/compare/v0.1.0...v0.2.0

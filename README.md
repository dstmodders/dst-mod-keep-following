# mod-keep-following

[![CI]](https://github.com/dstmodders/mod-keep-following/actions/workflows/ci.yml)
[![CD]](https://github.com/dstmodders/mod-keep-following/actions/workflows/deploy.yml)
[![Codecov]](https://codecov.io/gh/dstmodders/mod-keep-following)

[![Keep Following](preview.gif)](https://steamcommunity.com/sharedfiles/filedetails/?id=1835465557)

## Overview

Mod for the game [Don't Starve Together][] which is available through the
[Steam Workshop][] and allows players to follow/push others or one of the
supported entities.

| Default Keys                                        | Actions                                        |
| --------------------------------------------------- | ---------------------------------------------- |
| <kbd>Shift</kbd> + <kbd>LMB</kbd>                   | to keep following                              |
| <kbd>Shift</kbd> + <kbd>Ctrl</kbd> + <kbd>LMB</kbd> | to keep pushing and ignore the target distance |

To stop following use <kbd>WASD</kbd> movement keys, <kbd>Space</kbd> (in-game
action key) or click <kbd>LMB</kbd>.

You can also use the above key combinations on a Tent/Siesta Lean-to used by
another player to keep following or pushing him.

## Configuration

Don't like the default behaviour? Choose your own configuration to match your
needs:

| Configuration               | Default       | Description                                                              |
| --------------------------- | ------------- | ------------------------------------------------------------------------ |
| **Action Key**              | _Shift_       | Key used for both following and pushing                                  |
| **Push Key**                | _Ctrl_        | Key used in combination with an action key for pushing                   |
| **Reverse Buttons**         | _Disabled_    | When enabled, LMB and RMB will be swapped                                |
| **Compatibility**           | _Recommended_ | Which compatibility mode should be used?                                 |
| **Target Entities**         | _Default_     | Which target entities should be used for following and pushing?          |
| **Target Indicator Usage**  | _Binded_      | How should the target indicator interact with the action key?            |
| **Follow Method**           | _Default_     | Which follow method should be used?                                      |
| **Follow Distance**         | _2.5m_        | How close can you approach the target?                                   |
| **Follow Distance Keeping** | _Disabled_    | When enabled, you move away from the target within the follow distance   |
| **Push With RMB**           | _Disabled_    | When enabled, RMB + action key is used for pushing                       |
| **Push Mass Checking**      | _Enabled_     | When enabled, disables pushing entities with very high mass              |
| **Push Lag Compensation**   | _Enabled_     | When enabled, automatically disables the lag compensation during pushing |
| **Debug**                   | _Disabled_    | When enabled, displays debug data in the console                         |

## Documentation

The [LDoc][] documentation generator has been used for generating documentation,
and the most recent version can be found here:
https://docs.dstmodders.com/keep-following/

## License

Released under the [MIT License](https://opensource.org/licenses/MIT).

[cd]: https://img.shields.io/github/actions/workflow/status/dstmodders/mod-keep-following/cd.yml?branch=main&label=cd&logo=github
[ci]: https://img.shields.io/github/actions/workflow/status/dstmodders/mod-keep-following/ci.yml?branch=main&label=ci&logo=github
[codecov]: https://img.shields.io/codecov/c/github/dstmodders/mod-keep-following/main?logo=codecov&label=codecov
[don't starve together]: https://www.klei.com/games/dont-starve-together
[ldoc]: https://stevedonovan.github.io/ldoc/
[steam workshop]: https://steamcommunity.com/sharedfiles/filedetails/?id=1835465557

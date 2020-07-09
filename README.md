# dst-mod-keep-following

## Overview

Mod for the game [Don't Starve Together][] which is available through the
[Steam Workshop][] and allows players to follow/push others or one of the
supported entities.

| Default Keys             | Actions                                        |
| ------------------------ | ---------------------------------------------- |
| `Shift` + `LMB`          | to keep following                              |
| `Shift` + `Ctrl` + `LMB` | to keep pushing and ignore the target distance |

To stop following use `WASD` movement keys, `SPACEBAR` action key or click `LMB`.

You can also use the above key combinations on a Tent/Siesta Lean-to used by
another player to keep following or pushing him.

## Configuration

Don't like the default behaviour? Choose your own configuration to match your
needs:

| Configuration             | Options           | Default   | Description                                                                                   |
| ------------------------- | ----------------- | --------- | --------------------------------------------------------------------------------------------- |
| **Action key**            | _[keys]_          | _LShift_  | Key used for both following and pushing                                                       |
| **Push key**              | _[keys]_          | _LCtrl_   | Key used for pushing in combination with action key. Disabled when "Push with RMB" is enabled |
| **Push with RMB**         | _Yes/No_          | _No_      | Use RMB in combination with action key for pushing instead                                    |
| **Push mass checking**    | _Yes/No_          | _Yes_     | Enables/Disables the mass difference checking. Ignored for the ghosts pushing players         |
| **Push lag compensation** | _Yes/No_          | _Yes_     | Automatically disables lag compensation while pushing and restores the previous state after   |
| **Following method**      | _Default/Closest_ | _Default_ | Which following method should be used? Ignored when pushing                                   |
| **Target distance**       | _1.5m/2.5m/3.5m_  | _2.5m_    | How close can you approach the leader? Ignored when pushing                                   |
| **Keep target distance**  | _Yes/No_          | _No_      | Move away from a leader inside the target distance. Ignored when pushing                      |
| **Mobs**                  | _Default/All_     | _Default_ | Which mobs can be followed and pushed?                                                        |
| **Debug**                 | _Yes/No_          | _No_      | Enables/Disables the debug mode                                                               |

## Roadmap

Below are the features/improvements yet to be implemented:

- [ ] Auto-hide in a Bush Hat if equipped
- [ ] Auto-hide in a Snurtle Shell Armor if in the inventory
- [ ] Follow players through wormholes and possibly cave entrances

## License

Released under the [Unlicense](https://unlicense.org/).

[don't starve together]: https://www.klei.com/games/dont-starve-together
[steam workshop]: https://steamcommunity.com/sharedfiles/filedetails/?id=1835465557

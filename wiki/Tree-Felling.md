# Tree Felling

> **Use this page when:** players should clear trees with an axe or hatchet and optionally receive resources.

Tree Felling recognises a configured tool, accepts repeated strikes at a nearby tree, and replaces a felled tree with a log object. It can also clear nearby bushes. Arma does not provide a vanilla hand-held axe, so your mission needs a compatible mod weapon or custom content.

## Enable it

1. Open `MissionConfig/environmentConfig.sqf` and change `Waldo_TreeFelling_Enable` from `false` to `true`.
2. Give a player an axe-class weapon. The shipped `Waldo_TreeFelling_WeaponPatterns` accepts classnames containing `axe` or `hatchet`, ignoring case. Add a distinctive fragment if your weapon uses another name.
3. Look at a tree within three metres and use **Fell Tree / Clear Brush**. No ZEN module or placed interaction object is required.

## Change the result

Edit the existing rows in `MissionConfig/environmentConfig.sqf`. Every row below starts with `Waldo_TreeFelling_`.

| Setting suffix | Type | Shipped value | What it changes |
|---|---|---|---|
| `Enable` | Boolean | `false` | Installs the player action and swing handler. |
| `Range` | Number | `3` | Maximum distance to the tree, in metres. |
| `BaseHits` | Number | `3` | Starting number of accepted strikes. |
| `HeightFactor` | Number | `0.25` | Extra strikes per metre of tree height. |
| `HitCooldown` | Number | `0.7` | Minimum seconds between accepted strikes. |
| `WeaponPatterns` | Array of strings | `["axe", "hatchet"]` | Case-insensitive fragments matched against the held weapon classname. |
| `AllowedClasses` | Array of strings | `[]` | Exact extra tree classes to accept. Empty uses the normal model-name check. |
| `FallenClasses` | Array of CfgVehicles classnames | `["Land_WoodenLog_F"]` | General replacement pool. |
| `FallenClassesSmall`, `FallenClassesMedium`, `FallenClassesLarge` | Arrays of CfgVehicles classnames | `[]` each | Size-specific pools. Empty falls back to `FallenClasses`. |
| `SizeThresholds` | Two-number array | `[7, 15]` | Heights ending the small and medium groups, in metres. |
| `DirectionMode` | String | `"RANDOM"` | `"STRIKE"` falls away from the player; `"ORIGINAL"` follows the tree bearing. |
| `ClearBushes` | Boolean | `false` | Also clears nearby bushes. |
| `BushRadius` | Number | `4` | Bush-clearing radius in metres when enabled. |
| `ToolEfficiency` | HashMap | Shipped tool matches | Maps a weapon-class fragment to a positive strike multiplier. The longest match wins. |
| `ProtectedAreas` | Array | `[]` | Marker, trigger or area entries where felling is refused. |
| `Yields` | Array of `[classname, count]` rows | `[]` | CfgVehicles objects awarded after felling. |
| `RegrowSeconds` | Number | `-1` | `-1` or `0` disables regrowth; a positive value restores the tree after that many seconds. |

For example, add `"myMod_fireAxe"` to `WeaponPatterns` only if the existing `"axe"` fragment does not already match it. `ProtectedAreas` can list marker or trigger areas where felling is refused. Terrain-tree identities are not reliable across restarts, so regrowth is not persistent forestry.

## Script calls

Normal missions need no call after enabling the config row. WMP runs `[] call Waldo_fnc_TreeFellingInit` on each player interface, including JIP. It takes no arguments and returns `true` when installed or waiting for runtime state, otherwise `false`. A repeat call does not add another action. `[] call Waldo_fnc_TreeFellingStop` removes that local action, restores a previous IMS swing callback and returns `true` on an interface client. It returns `false` on a machine without an interface. Neither call fells a tree directly; players use the action while holding a matching tool.

## If no action appears

Check that the enable row is `true`, the player holds a class matching `WeaponPatterns`, and the target is a tree within `Range`. A non-matching swing creates no tree-strike request.

## See also

- [Construction Objects](Construction-Objects)
- [Optional Feature Extensions](Optional-Feature-Extensions) for protected areas, efficiency and regrowth details

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)

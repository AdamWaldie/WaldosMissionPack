# Tree Felling

> **Use this page when:** players should clear trees with an axe or hatchet and optionally receive resources.

Tree Felling recognises a configured tool, accepts repeated strikes at a nearby tree, and replaces a felled tree with a log object. It can also clear nearby bushes. Arma does not provide a vanilla hand-held axe, so your mission needs a compatible mod weapon or custom content.

## Enable it

1. Open `MissionConfig/environmentConfig.sqf` and change `Waldo_TreeFelling_Enable` from `false` to `true`.
2. Give a player an axe-class weapon. The shipped `Waldo_TreeFelling_WeaponPatterns` accepts classnames containing `axe` or `hatchet`, ignoring case. Add a distinctive fragment if your weapon uses another name.
3. Look at a tree within three metres and use **Fell Tree / Clear Brush**. No ZEN module or placed interaction object is required.

## Change the result

Edit the existing rows in `MissionConfig/environmentConfig.sqf`. `Range = 3` controls reach, `BaseHits = 3` sets the minimum accepted strikes, and `HitCooldown = 0.7` seconds prevents unrealistically rapid hits. `DirectionMode = "RANDOM"` chooses the log direction. `"STRIKE"` sends it away from the player. `"ORIGINAL"` follows the original bearing. `FallenClasses` defaults to `Land_WoodenLog_F`. The small, medium and large class lists are empty until you supply alternatives. `Yields` is empty by default. Add `[CfgVehicles classname, count]` rows if the mission should award objects.

`ProtectedAreas` can list marker or trigger areas where felling is refused. `RegrowSeconds = -1` means no regrowth; a positive value restores a tree during the current mission only. Terrain-tree identities are not reliable across restarts, so this is not persistent forestry.

## If no action appears

Check that the enable row is `true`, the player holds a class matching `WeaponPatterns`, and the target is a tree within `Range`. A non-matching swing creates no tree-strike request. `Waldo_fnc_TreeFellingInit` and `Waldo_fnc_TreeFellingStop` install and remove the local action if you need runtime control.

## See also

- [Construction Objects](Construction-Objects)
- [Optional Feature Extensions](Optional-Feature-Extensions) for protected areas, efficiency and regrowth details

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)

# Tree felling

Axe/hatchet-driven tree replacement, brush clearing, yields, protected
areas and optional session-only regrowth. Arma 3 has **no vanilla axe** —
the mission needs an axe/hatchet weapon from a mod or custom content.
"Automatic" pattern once enabled — no ZEN module, no registration call.

## Config (`MissionConfig\environmentConfig.sqf` — shared)

```sqf
["Waldo_TreeFelling_Enable", false],
["Waldo_TreeFelling_Range", 3],                 // metres, axe interaction range
["Waldo_TreeFelling_BaseHits", ...],            // base strikes required
["Waldo_TreeFelling_HeightFactor", ...],        // extra strikes from tree height
["Waldo_TreeFelling_HitCooldown", ...],
["Waldo_TreeFelling_WeaponPatterns", ["axe", "hatchet"]], // case-insensitive classname fragments treated as axes
["Waldo_TreeFelling_AllowedClasses", []],       // exact tree classes when model path lacks "tree"; normally leave empty
["Waldo_TreeFelling_FallenClasses", [...]],     // general replacement log pool
["Waldo_TreeFelling_FallenClassesSmall", []], ["Waldo_TreeFelling_FallenClassesMedium", []], ["Waldo_TreeFelling_FallenClassesLarge", []], // empty falls back to FallenClasses
["Waldo_TreeFelling_SizeThresholds", [...]],    // [end of small, end of medium] metres, e.g. [7, 15]
["Waldo_TreeFelling_DirectionMode", "RANDOM"],  // RANDOM | STRIKE (away from player) | ORIGINAL
["Waldo_TreeFelling_ClearBushes", ...], ["Waldo_TreeFelling_BushRadius", ...],
["Waldo_TreeFelling_ToolEfficiency", createHashMapFromArray [ /* classname/fragment -> multiplier, e.g. 2 = double effective, 0.5 = half */ ]],
["Waldo_TreeFelling_ProtectedAreas", []],       // marker/trigger/area names where felling is disallowed
["Waldo_TreeFelling_Yields", []],               // [CfgVehicles classname, count] reward rows
["Waldo_TreeFelling_RegrowSeconds", -1]         // -1 or 0 disables regrowth
```

## Beginner test

1. Set `Waldo_TreeFelling_Enable` to `true`.
2. Confirm the axe weapon's classname contains `"axe"` or `"hatchet"` (the
   shipped patterns already match e.g. `MyMod_FireAxe`,
   `myMod_small_axe` — comparison is case-insensitive); otherwise add a
   distinctive fragment to `Waldo_TreeFelling_WeaponPatterns`.
3. Equip the axe, look at a tree within 3 m, use **Fell Tree / Clear Brush**.

Start/stop the local action with `Waldo_fnc_TreeFellingInit` /
`Waldo_fnc_TreeFellingStop`.

## Gotchas

- An exact classname match in `ToolEfficiency` wins over a fragment match;
  the longest matching fragment wins among fragments.
- `SizeThresholds` of `[7, 15]` means a 6 m tree is small, 10 m medium, 20 m
  large.
- No ZEN module — script/config only.
- Terrain-object identities aren't stable enough for restart-safe
  regrowth persistence; use mission-level state tracking instead if that
  matters (`wiki/Optional-Feature-Extensions.md`).

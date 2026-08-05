# Explosive wall breaching

Requires ACE Explosives. Server-validated class profiles let a mission make
specific wall/structure classes breachable with configured explosives and
required accumulated force. "Automatic + profiles" pattern: enabling starts
the handler, but only classes with a matching profile react.

## Config (`MissionConfig\environmentConfig.sqf` — shared)

```sqf
["Waldo_Breaching_Enable", false],              // harmless while false, even with profiles present
["Waldo_Breaching_ShowNotifications", false],   // opt-in confirmation card to the player who placed the successful charge
["Waldo_Breaching_Profiles", createHashMapFromArray [
    ["Land_City2_8m_F", createHashMapFromArray [   // exact target CfgVehicles classname — ready-to-test example
        ["radius", 5],                              // charge must explode within 5 m
        ["explosives", ["DemoCharge_Remote_Ammo", "SatchelCharge_Remote_Ammo"]], // CfgAmmo classnames, NOT magazine names
        ["requiredStrength", 1],                    // accumulated force needed
        ["destroyOriginal", true],
        ["hideOriginal", true],
        ["deleteOriginal", false],                  // false allows Waldo_fnc_BreachingReset
        ["replacements", []]                        // debris/partial-wall rows, advanced
    ]]
]],
["Waldo_Breaching_ExplosiveStrengths", createHashMapFromArray [
    ["DemoCharge_Remote_Ammo", 1], ["SatchelCharge_Remote_Ammo", 3]
]]
```

## Beginner test

1. Place the vanilla `Land_City2_8m_F` wall in Eden.
2. Set `Waldo_Breaching_Enable` to `true`.
3. Detonate an ACE M112 demo charge or satchel within 5 m of the wall.

Only the exact configured wall class reacts — unrelated walls/buildings are
untouched. Successful breaches are silent by default (no notification lane
used); set `Waldo_Breaching_ShowNotifications` to `true` to opt in.

## Requiring more than one charge

`requiredStrength` on the profile compares against `ExplosiveStrengths` — a
profile needing `2` requires two demo charges (strength `1` each) or one
satchel (strength `3`). Scripted subclasses inherit their configured base
ammo class's strength.

## Adding another breachable class

Copy the entire target/profile block, comma-separate, replace only the
target classname for the initial test — keep `replacements: []` until the
basic breach works. A malformed classname affects no object silently;
diagnostics reports profile count and ACE dependency state.

## Advanced: replacement debris rows

```sqf
["CfgVehicles_Classname", [leftRight, forwardBack, upDown], yaw, "CAN_COLLIDE", "ATL", scale]
```

Offsets use the original wall's model axes in metres; `yaw` adds to the old
wall direction; placement mode/position mode/scale may be omitted (default
`"CAN_COLLIDE"`, `"ATL"`, `1`). Complex debris layouts need in-game testing
— WMP cannot cut a new hole into arbitrary model collision geometry.

## Gotchas

- Keep `deleteOriginal` false unless permanent deletion is specifically
  required — it forecloses `Waldo_fnc_BreachingReset`.
- `Waldo_fnc_BreachingStop` stops the system; `Waldo_fnc_BreachingReset`
  restores hidden non-deleted originals and removes tracked replacements.
- No ZEN module — script/config only.

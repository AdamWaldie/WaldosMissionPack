# AI rebalance (AITweak)

**Profile names and config location changed.** Config now lives in
`MissionConfig\aiConfig.sqf` (`shared` scope, loaded automatically on every
machine from `init.sqf` — do not duplicate the call there):

```sqf
["Waldo_AIRebalance_Enable", true],
["Waldo_AIRebalance_Profile", "LINE"],  // MILITIA | LINE | VETERAN | ELITE
["Waldo_AIRebalance_Mode", "DAY"],      // DAY | NIGHT
["Waldo_AI_ApplyMode", "BOTH"],         // EXISTING | NEW | BOTH
```

Applies automatically — there is **no `[...] call Waldo_fnc_AITweak;` line to
add** anymore; the automatic handler follows AI locality across server,
client and headless clients on its own once `Waldo_AIRebalance_Enable` is
`true`.

- **`LINE` is the new default profile** (replacing the old `LEGACY` default)
  — it's the WMP baseline for editor and Zeus AI. `MILITIA`, `VETERAN`,
  `ELITE` are the other named profiles, roughly weakest to strongest.
  `LEGACY` still exists as a compatibility profile that preserves the pack's
  pre-rewrite balance — pick it only if the mission previously ran WMP and
  should not feel different.
- `Waldo_AIRebalance_Mode` is `"DAY"` or `"NIGHT"` — NIGHT uses deliberately
  lower low-light values (reduces unaided spotting more than NVG-assisted
  spotting).
- `Waldo_AI_ApplyMode` replaces the old implicit "just editor units" scope:
  `EXISTING` only affects AI present when the handler starts, `NEW` only
  affects AI created afterward, `BOTH` (default) covers both populations.
- Optional filters, ADVANCED TUNING (leave alone unless testing): `Waldo_AI_IncludedSides`,
  `Waldo_AI_IncludedFactions`, `Waldo_AI_ExcludedFactions`,
  `Waldo_AI_ExcludedClasses`, `Waldo_AI_SkillVariance` (random offset, `0` =
  deterministic), `Waldo_AI_RestoreOnStop` (restores captured skills when the
  handler stops).
- All-machine initialiser by design: AI ownership and locality can move
  across server, client, and headless-client machines, so don't restructure
  this to run server-only.
- Runtime changes are also available via **Waldos Mission Modules > AI
  Rebalance - Control** in Zeus, which publishes the change through the same
  ordered runtime-setting bundle used at join — same effect as editing the
  config file, useful for adjusting mid-mission without a restart.

## Improved AI Helicopter Landings

A related but separate system in the same config file (`Waldo_ImprovedHelicopterLanding_*`
in `aiConfig.sqf`) — see `references/misc-mission-maker-tools.md` if the user
only needs a one-line pointer, or `wiki/Improved-AI-Helicopter-Landings.md`
for the full tuning reference (trigger distance, glideslope, tree clearance,
go-around policy). Enabled by default; needs a LAND/UNLOAD/TRANSPORT
UNLOAD/GET OUT waypoint on the AI pilot to engage. No ZEN module.

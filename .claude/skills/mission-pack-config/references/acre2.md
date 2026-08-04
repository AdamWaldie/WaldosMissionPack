# ACRE2 radio setup

Requires the ACRE2 mod (`acre_main` in `CfgPatches`) — check `mod-detection.md`
first if unsure it's in play.

## Config (`init.sqf`)

```sqf
private _RadioSetups = [
    ["Viking-1-1", [1,5]],   // [group name, [LR channel numbers]]
    ["Viking 5",   [2,7]],
    ["Banshee",    [4,1]]
];
[_RadioSetups] call Waldo_fnc_ACRE2Init;
```

- **Group names must match exactly** what's set in the Eden Editor group
  name field — this is the #1 source of "radios aren't assigning" reports.
  If it isn't working, ask the user to confirm the exact Eden group name
  character-for-character (case and spacing matter).
- Channel numbers are **1-indexed** positions into
  `Waldo_ACRE2Setup_LRChannels_BLUFOR/OPFOR/IND/CIV` (set earlier in
  `init.sqf`) — not raw channel numbers. `[1,5]` means "first and fifth
  entries in that side's channel array," so the array must have at least 5
  entries for that example to resolve.
- Short-range (AN/PRC-343) radios are assigned automatically based on squad
  numerical designations — no config needed for those.
- CEOI (the radio reference card) auto-populates in the map screen from this
  same setup; no separate configuration.

## Known limitation

Channel *naming* via `setPresetChannelField "label"` does not display
in-game (it causes radio inconsistency) — this is why the labelling code in
`ACRE2Init.sqf` is commented out. Channel names only ever show in the CEOI
map entry; the radios themselves are numbered only. Don't try to "fix" this
by re-enabling that code — it's a known ACRE2 limitation, not a WMP bug.

## Jamming interaction

If the mission also uses WMP's radio jamming (see `jamming.md`), the ACRE2
signal model must be **LOS Multipath** (default) or **Arcade** — jamming's
custom signal hook is never called under *LOS Simple*.

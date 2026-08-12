# ACRE2 radio setup

Requires the ACRE2 mod (`acre_main` in `CfgPatches`) — check `mod-detection.md`
first if unsure it's in play.

**Full rewrite from the old group-name/channel-number array.** Radio setup is
now entirely pure-data in `MissionConfig\acreConfig.sqf`. WMP loads it
automatically during pre-init, server init and player-local init — there is
**no call to make in `init.sqf`** anymore. If you see a mission still calling
`Waldo_fnc_ACRE2Init` with a `_RadioSetups` array, that's the old model; port
it to `acreConfig.sqf` (below), don't keep it.

## Config (`MissionConfig\acreConfig.sqf`)

```sqf
["enabled", true],                    // master switch — false leaves ACRE radios untouched
["strict", true],                     // true = reject/report authoring mistakes (duplicate PRC-343 slots etc.)
["prc343PresetPolicy", "FULL_RANGE"], // FULL_RANGE = blocks 1-16 all sides; SIDE_ISOLATED = separated but blocks 1-5 on combat sides
["namedDisplays", true],              // label supported PRC-148/152/117F channel displays
["notifyAssignmentProblems", true],   // warn the affected player when their setup fails to apply
["readinessTimeoutSeconds", 120],     // ADVANCED TUNING: how long WMP waits for ACRE's own radio-ID
                                       // conversion before giving up and retrying — raise this on a
                                       // heavy modset/slow-loading mission if RPT or WMP Diagnostics
                                       // repeatedly shows a timeout here; WMP's own overwrite of any
                                       // Eden "ACRE Radio Setup" unit attribute is delayed, not lost,
                                       // until the automatic retry catches up
["additionalRadioProfiles", []],      // ADVANCED: tested third-party carried radios only — leave empty
["radioOverrides", []],               // optional per-UID/VARIABLE/ROLE exceptions, see below
["sides", [ /* per-side [side, ACRE preset, nets, groups] blocks — see below */ ]],
["babel", createHashMapFromArray [ /* language config — see below */ ]]
```

### Sides, nets and groups

Each side is `[SIDE, official ACRE preset, NETS, GROUPS]` — do not invent or
change the official ACRE preset (`"default3"` for WEST etc.), that's ACRE's
own side preset, not a WMP value.

A **net** is `[key, display label, radio family, one value]` — it has exactly
one channel/frequency, never a per-radio list:

```sqf
["PLT1", "PLATOON 1", "PRC_LR", 2],   // PRC-148/152/117F channel 2 (they interoperate on matching channel numbers)
["BF_HANDHELD", "BF HANDHELD", "BF888", 6],
["VHF_COMMON", "VHF COMMON", "LEGACY_VHF", 51.000]
```

Radio families: `PRC_LR` (PRC-148/152/117F, share side-preset channels),
`BF888` (ACRE_BF888S, 16ch different band), `SEM52` (ACRE_SEM52SL, 12ch
different band), `LEGACY_VHF` (ACRE_PRC77/ACRE_SEM70, explicit MHz). A radio
can never consume a net from a mismatched family, even if the number happens
to fit — WMP diagnoses the mismatch by group, radio occurrence and expected
family.

A **group** is `[editor group ID, assignment rows]`. Group ID matching is
case/separator-insensitive (`VIKING-2-3`, `Viking 2-3`, `viking_2_3` all
match). Each assignment row is
`[base radio class, "ALL" or same-type occurrence (1-based), target, ear]`:

```sqf
["ACRE_PRC343", 1, [2, 3], "LEFT"],      // first 343: Block 2/Channel 3, left ear
["ACRE_PRC343", 2, [2, 4], "RIGHT"],     // second 343: Block 2/Channel 4, right ear
["ACRE_PRC152", 1, "PLT1", "RIGHT"],     // first 152 on the PLT1 net, right ear
["ACRE_PRC152", 2, "AIRGND", "LEFT"]     // second 152 on AIRGND, left ear
```

`"ALL"` is the readable default for every carried radio of that class — use
it when every radio of that class should be identical. When duplicate
radios differ, switch to numbered occurrence rows for *every* one of them;
**mixing `ALL` and numbered rows for the same class in one group is
rejected**. PRC-343 target is `[block, channel]`; `[]` asks WMP to infer the
slot from the group's callsign (e.g. `Viking 2-3` → block 2, channel 3),
otherwise WMP uses deterministic collision-safe allocation. Ears (`LEFT`,
`RIGHT`, `BOTH`/`CENTER`) work independently per radio, including multiple
PRC-343s. A radio present in a player's inventory with no matching row is
left untouched; PTT, volume and speaker settings always remain player-owned.

### Overrides (per-player/role exceptions)

```sqf
[
    "WEST",                    // side this exception belongs to
    ["ROLE", "JTAC"],          // ["UID", "..."], ["VARIABLE"/"VARIABLENAME", "..."], or ["ROLE", "..."]
    "MERGE",                   // MERGE = only replaces the listed radios, keeps the rest of the group template; REPLACE = discards the group template first
    [["ACRE_PRC152", "ALL", "AIRGND", "RIGHT"]]
]
```

### Babel (multilingual, optional)

```sqf
["babel", createHashMapFromArray [
    ["enabled", false],   // false = inert even with example languages present
    ["languages", [["common", "Common"], ["en", "English"], ["ru", "Russian"]]],
    ["sideDefaults", [["WEST", ["common", "en"], "en"], ["EAST", ["common", "ru"], "ru"]]],
    ["unitOverrides", [
        // [["UID", "7656119..."], ["common", "en", "ru"], "en"]
        // [["VARIABLENAME", "interpreter_1"], ["common", "en", "ru"], "ru"]
    ]],
    ["changeOnSideChange", false],  // false = side switch does not erase already-assigned languages
    ["followPlayerUnit", true]      // true = reapply on respawn's replacement unit
]]
```

See `wiki/ACRE2-Babel-Configuration.md` for the full override-matching rules.

## Loadout saving and respawn (important behaviour change)

ACRE's `_ID_n` class is a temporary local physical-radio instance — it must
never be persisted as an inventory classname. WMP now keeps two explicit
paths, neither of which polls or continually retunes radios during play:

- **Normal Save Respawn Loadout** filters every unique radio back to its
  base class and stores the player's channel/ear/frequency/volume/selected
  radio state separately by `[base class, same-type occurrence]`. Respawn
  creates fresh radios, then restores that snapshot. The `acreConfig.sqf`
  plan is the *initial* setup and the fallback when no usable snapshot
  exists — it is not an ongoing enforcement policy.
- **INIDBI2 persistence** with `Waldo_Persistence_SaveRadios = true` (see
  `persistence.md`) persists the same per-player state across sessions.

PTT keybind defaults are never changed by either path.

## CEOI, PRC-343 and Babel wiki pages

- `wiki/ACRE-2-Long-Range-Radio-Presetting.md` — net/channel detail
- `wiki/ACRE-2-Squad-Level-Radios-AN-PRC‐343-Automatic-Setup.md` — PRC-343 block/channel policy
- `wiki/ACRE2-Automated-CEOI-Document.md` — the auto-populated map CEOI entry (unchanged: still auto-builds from the current plan, no separate config)
- `wiki/ACRE2-Babel-Configuration.md` — full Babel override rules

## Jamming interaction

If the mission also uses WMP's radio jamming (see `jamming.md`), the ACRE2
signal model must be **LOS Multipath** (default) or **Arcade** — jamming's
custom signal hook is never called under *LOS Simple*.

## Emergency fallback

The frozen `Waldo_fnc_*_Legacy` functions are a manual emergency fallback
only — don't recommend them for normal setup, the `acreConfig.sqf` model is
the supported path.

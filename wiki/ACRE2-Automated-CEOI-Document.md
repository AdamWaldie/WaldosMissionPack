# ACRE2 Automated CEOI

> **Use this page when:** players need an authoritative in-game reference for their configured radio nets.

The CEOI is the player's in-game radio reference. WMP combines the mission's starting side/group
setup with what the player's computer actually applied. It lists the side, callsign, PRC-343
block/channel and named long-range nets, and reports any setup problem instead of silently guessing.

Only the player's side is shown. **Squad Radio Assignments** appears only when at least one group on
that side has a valid PRC-343 assignment; groups without one are omitted instead of producing empty
placeholder rows. The list uses the group names as written in `MissionConfig/acreConfig.sqf`—for
example, `VIKING 2-3`—rather than the separator-free keys WMP uses to match editor group IDs.
If nobody is assigned a PRC-343, the complete section is omitted. The current
group's short-range assignment and authored long-range net assignments are highlighted green before
the mission starts. After ACRE is ready, matching live radio read-back is also green. Carried-radio lines
identify base class, same-type occurrence, resolved request, ear, applicable failures and the count
of preserved/unmanaged radios. Missing optional templates are not failures. Frequency-radio
requests are marked as asynchronous/unverified because ACRE exposes no public frequency read-back.

The planned CEOI is created from the pure mission configuration during player-local briefing setup,
so it is visible on the map **before Continue** even when ACRE has not finished creating physical
radio IDs. If the authoritative server plan has not arrived yet, WMP compiles an identical
display-only preview locally; that preview is never used to tune a radio. After ACRE starts, the
record is rebuilt from authoritative plan and live read-back. Join, group change and player-object
replacement all replace the previous record instead of duplicating it. Group changes update this
reference only and never retune radios.

## Set up the CEOI

Mission makers do not call this for normal setup. Edit `MissionConfig\acreConfig.sqf`;
`Waldo_fnc_ACRE2Init` handles generation. The shipped file contains a WEST example and empty
EAST, GUER and CIV group lists. Copy a group row within the correct side, then replace its
Eden group ID and radio assignments. Give each long-range net a stable key and use that key
in the group's assignments.

There is no CEOI object, map marker or per-player classname to register. The input is the radio plan in `acreConfig.sqf`: side, matching group name, PRC-343 block and channel, and any named long-range nets. Start with [Squad-level radio setup](ACRE-2-Squad-Level-Radios-AN-PRC‐343-Automatic-Setup) for the short-range row shape and [Long-range presetting](ACRE-2-Long-Range-Radio-Presetting) for named nets. The CEOI displays that plan before briefing ends, then adds live read-back after ACRE starts. It does not tune a radio when a player opens the diary.

## Configuration reference

The `sides` setting is an array of side rows. The CEOI reads these rows; it has no separate
settings or script parameters. Leave the official ACRE preset for each side in place unless
you are changing the radio plan itself.

| Part of the `sides` setting | Type | What to supply |
| --- | --- | --- |
| Side row | Array | `[side ID, ACRE preset, named nets, groups]`. The shipped IDs are `WEST`, `EAST`, `GUER` and `CIV`. |
| Side ID | String | The Arma side whose players receive these assignments. |
| ACRE preset | String | The side's official preset, such as WEST's `default3`. |
| Named nets | Array of net rows | Use `[]` if this side has no named nets. A net row is `[key, label, family, value]`. |
| Net key and label | String, String | A stable key such as `PLT1`, then the name players see, such as `PLATOON 1`. |
| Net family and value | String, Number | For example, `PRC_LR` with channel `2`; the compatible family determines whether the number is a channel or frequency. |
| Groups | Array of group rows | Use `[]` if no groups on this side have assignments. A row is `[Eden group ID, assignments]`. |
| Eden group ID | String | The group name as set in Eden. The CEOI prints this spelling, although matching ignores common separators and case. |
| Assignments | Array of assignment rows | Each row is `[radio class, occurrence, target, ear]`. |
| Radio class | String | The carried radio's base class, such as `ACRE_PRC343` or `ACRE_PRC152`. |
| Occurrence | String or Number | `"ALL"` for every radio of this class, or `1`, `2`, and so on for individually configured copies. Do not mix both forms for one class. |
| Target | Array, String or Number | PRC-343 uses `[block, channel]` or `[]` for callsign inference. Compatible long-range radios can use a named net key or a supported direct value. |
| Ear | String | `LEFT`, `RIGHT`, `BOTH` or `CENTER`. |

The `sides` setting is present by default, but only the shipped WEST example has populated
groups. The CEOI is read-only: it returns no value to a mission-maker script and does not
change a radio when opened. The normal call path is WMP's automatic pre-briefing and
player-local ACRE setup, including join and player replacement.

## If a radio line is missing

Check the group name and radio assignment in `MissionConfig/acreConfig.sqf`. The CEOI omits groups without a valid PRC-343 assignment instead of displaying blank rows. A planned line can appear before ACRE starts; read the later live status before assuming the radio was physically tuned.

## See also

- [Long-Range Radio Presetting](ACRE-2-Long-Range-Radio-Presetting)
- [Babel Configuration](ACRE2-Babel-Configuration)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)

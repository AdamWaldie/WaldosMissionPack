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

Mission makers do not call this for normal setup. Edit `MissionConfig\acreConfig.sqf`; `Waldo_fnc_ACRE2Init` handles generation.

## If a radio line is missing

Check the group name and radio assignment in `MissionConfig/acreConfig.sqf`. The CEOI omits groups without a valid PRC-343 assignment instead of displaying blank rows. A planned line can appear before ACRE starts; read the later live status before assuming the radio was physically tuned.

## See also

- [Long-Range Radio Presetting](ACRE-2-Long-Range-Radio-Presetting)
- [Babel Configuration](ACRE2-Babel-Configuration)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)

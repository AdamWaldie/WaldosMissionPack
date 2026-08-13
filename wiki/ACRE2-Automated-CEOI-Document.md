# ACRE2 Automated CEOI

> **Use this page when:** players need an authoritative in-game reference for their configured radio nets.

The CEOI is the player's in-game radio reference. WMP combines the mission's starting side/group
setup with what the player's computer actually applied. It lists the side, callsign, PRC-343
block/channel and named long-range nets, and reports any setup problem instead of silently guessing.

Only the player's side is shown. **Squad Radio Assignments** appears only when at least one group on
that side has a valid PRC-343 assignment; groups without one are omitted instead of producing empty
placeholder rows. If nobody is assigned a PRC-343, the complete section is omitted. The current
group's short-range assignment and radio-specific net tunings are highlighted. Carried-radio lines
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

Mission makers do not call this for normal setup. Edit `MissionConfig\acreConfig.sqf`; `Waldo_fnc_ACRE2Init` handles generation. The full audit mission includes a core-console action to force a rebuild while checking physical radios.

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)

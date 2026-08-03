# ACRE2 Automated CEOI

> **Use this page when:** players need an authoritative in-game reference for their configured radio nets.

The CEOI is the player's in-game radio reference. WMP combines the mission's starting side/group
setup with what the player's computer actually applied. It lists the side, callsign, PRC-343
block/channel and named long-range nets, and reports any setup problem instead of silently guessing.

Only the player's side is shown. The current group's short-range assignment and radio-specific net tunings are highlighted. Carried-radio lines identify base class, same-type occurrence, resolved request, ear, applicable failures and the count of preserved/unmanaged radios. Missing optional templates are not failures. Frequency-radio requests are marked as asynchronous/unverified because ACRE exposes no public frequency read-back.

The record is rebuilt after join, group change and player-object replacement, replacing the previous record instead of duplicating it. Group changes update this reference only and never retune radios.

Mission makers do not call this for normal setup. Edit `MissionConfig\acreConfig.sqf`; `Waldo_fnc_ACRE2Init` handles generation. The full audit mission includes a core-console action to force a rebuild while checking physical radios.

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)

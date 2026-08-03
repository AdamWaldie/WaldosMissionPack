# ACRE2 Automated CEOI

> **Use this page when:** players need an authoritative in-game reference for their configured radio nets.

`Waldo_fnc_ACRE2BuildCEOI` combines the server's versioned plan with the most recent verified local radio application. The authoritative side, callsign, PRC-343 block/channel and long-range nets come from one source; the verification section reports what the client actually applied.

Only the player's side is shown. The current group's short-range assignment and radio-specific net tunings are highlighted. Carried-radio lines identify base class, same-type occurrence, resolved request, ear, applicable failures and the count of preserved/unmanaged radios. Missing optional templates are not failures. Frequency-radio requests are marked as asynchronous/unverified because ACRE exposes no public frequency read-back.

The record is rebuilt after join, group change and player-object replacement, replacing the previous record instead of duplicating it. Group changes update this reference only and never retune radios.

Mission makers do not call this for normal setup. Edit `MissionConfig\acreConfig.sqf`; `Waldo_fnc_ACRE2Init` handles generation. The full audit mission includes a core-console action to force a rebuild while checking physical radios.

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)

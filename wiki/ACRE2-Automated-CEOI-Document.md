# ACRE2 Automated CEOI

> **Use this page when:** players need an authoritative in-game reference for their configured radio nets.

`Waldo_fnc_ACRE2BuildCEOI` combines the server's versioned plan with the most recent verified local radio application. The authoritative side, callsign, PRC-343 block/channel and long-range nets come from one source; the verification section reports what the client actually applied.

Only the player's side is shown. The current group's short-range assignment and logical long-range nets are highlighted. Carried-radio lines identify base class, same-type occurrence, resolved channel/frequency, ear, missing assignments and the count of preserved/unmanaged radios. This makes a missing second radio or failed write visible rather than presenting a plan as verified fact.

The record is rebuilt after join, group change and enabled player-object replacement, replacing the previous record instead of duplicating it. A group change always refreshes the reference; it retunes radios only when `retuneOnGroupChange` is enabled.

Mission makers do not call this for normal setup. Edit `MissionConfig\acreConfig.sqf`; `Waldo_fnc_ACRE2Init` handles generation. The full audit mission includes a core-console action to force a rebuild while checking physical radios.

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)

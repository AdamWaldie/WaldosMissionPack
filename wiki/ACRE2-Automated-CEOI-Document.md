# ACRE2 Automated CEOI

> **Use this page when:** players need an authoritative in-game reference for their configured radio nets.

`Waldo_fnc_ACRE2BuildCEOI` generates the CEOI directly from the server's versioned ACRE plan. It does not rediscover groups or reconstruct names from separate variables, so the displayed side, callsign, PRC-343 block/channel and long-range nets cannot diverge from radio assignment.

Only the player's side is shown. The current group's short-range assignment and logical long-range nets are highlighted. The record is rebuilt after join and player-object replacement, replacing the previous record instead of duplicating it.

Mission makers do not call this for normal setup. Edit `acreConfig.sqf`; `Waldo_fnc_ACRE2Init` handles generation. The full audit mission includes a core-console action to force a rebuild while checking physical radios.

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)

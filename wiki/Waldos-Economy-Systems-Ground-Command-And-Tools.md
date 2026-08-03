# Economy Ground Command and Tools

> **Use this page when:** you need Ground Command, commitment mode, setup export, presets, purge, or status tools.

_Associated Files: MissionScripts\EconomySystems\Command\ (`Waldo_fnc_EcoCommand_*`), MissionScripts\EconomySystems\Core\ (`Waldo_fnc_EcoCore_*`)_

Alongside the four economy systems, [Waldos Economy Systems](Waldos-Economy-Systems) ships several management tools, all reached from the **Waldos Economy Systems** menu in Zeus.

## Ground Command

By default, any player on a side can spend that side's resources. **Ground Command** lets you restrict that to trusted players: designate someone as Ground Command and only they (and Zeus) may spend resources, order research, and manage/upgrade buildings for the side. This gives you a clear commander role without locking everyone else out of the rest of the game.

Assign it live in Zeus: **Waldos Economy Systems → Ground Command**, then pick the player(s).

> Ground Command is intentionally **Zeus-only** — its permission keys are tied to a player's current connection, so it can't be reliably pre-set from the editor. Assign it once the mission is running.

## Commitment mode

While you are configuring the economy, the dynamic menus continuously poll for changes. **Commitment mode** freezes those config-catalog refreshes, reducing server load. Turn it **on** once you have finished configuring (you can still play normally; you just won't be editing catalogs). Toggle it in Zeus, or set it at mission start:

```sqf
missionNamespace setVariable ["Waldo_Economy_CommitmentMode", true, true];
```

## Export / Import

Use the normal Economy Zeus modules as visual builders, then open **Configuration: Build Mission Setup**. Its combined screen has one primary authoring action and two compatibility actions:

* **BUILD + COPY** asks each selected system to translate its current module-authored setup into paste-ready `MissionConfig\economyConfig.sqf` calls, then copies the complete block to the clipboard. The result uses the same public functions documented for hand-authored missions and includes their pre-filled settings and placements.
* **Config Copy** exports the original portable catalogue string containing resources, research, buildings and purchases.
* **Import** loads a portable configuration string. **Additive Import** merges it instead of replacing existing catalogues.

Use these modes to:

* save a configuration you built live in Zeus,
* share a configuration between missions, or
* bake only the catalogues into a mission via `Waldo_Economy_ConfigString`, or
* bake the complete authored layout into `MissionConfig\economyConfig.sqf` (see [Setup & Configuration](Waldos-Economy-Systems-Setup-And-Configuration)).

The recommended workflow is **configure and place everything with the Zeus modules in a clean authoring session, press BUILD + COPY, then paste the generated setup calls into `MissionConfig\economyConfig.sqf`**. On later mission runs those calls recreate the authored setup without requiring Zeus. Use CONFIG COPY instead when positions and placed fixtures should remain mission-specific.

## Presets

Three bundled presets give you a ready-made economy at increasing complexity — **LOW** (a single resource and research) through **HIGH** (a deep, interlocking economy). Apply one from the Zeus preset menu, from `Waldo_Economy_Preset`, or by dropping a preset composition. Faction catalogues (`NATO`, `CSAT`, `AAF`, `SYNDIKAT`) tailor each side's purchasable vehicles.

## Purge

**Purge** cleanly removes the entire economy suite from the running mission — deletes its world objects and markers and stops its loops — if you decide you no longer want it. Purge is **permanent for that mission**: it also prevents joining (JIP) players from re-initialising the suite, so it is a teardown, not a reset. Restart the mission to run the economy again afterwards.

## Status check (for scripters)

`call Waldo_fnc_EcoCore_isActive` returns whether the suite is currently running, so you can gate dependent scripts, e.g. `waitUntil { call Waldo_fnc_EcoCore_isActive };`. Failed player actions (not enough resources, unmet requirements, no drop point in range) use a branded timed notice instead of silently failing or burying the reason in game chat.

## See also

* [Setup & Configuration](Waldos-Economy-Systems-Setup-And-Configuration)
* [Waldos Economy Systems hub](Waldos-Economy-Systems)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)

# Economy Ground Command and Tools

> **Use this page when:** you need Ground Command, commitment mode, setup export, presets, purge, or status tools.

_Associated Files: MissionScripts\EconomySystems\Command\ (`Waldo_fnc_EcoCommand_*`), MissionScripts\EconomySystems\Core\ (`Waldo_fnc_EcoCore_*`)_

Alongside the four economy systems, [Waldos Economy Systems](Waldos-Economy-Systems) ships several management tools, all reached from the **WMP Economy Systems** menu in Zeus.

## Setup values and script result

| Control | Type and default | Where it belongs | Result |
| --- | --- | --- | --- |
| Ground Command designation | Connected player Object selected in ZEN | Live Zeus module | Grants that connection spending/order authority for its side. |
| `Waldo_Economy_CommitmentMode` | Boolean; unset in the shipped `initServer.sqf` | Optional server setup or Zeus control | `true` freezes catalogue refreshes after authoring. |
| `Waldo_Economy_Preset` | String: `LOW`, `MEDIUM` or `HIGH`; unset by default | Optional `initServer.sqf` value or preset composition | Loads the chosen catalogue at economy start. |
| `Waldo_Economy_ConfigString` | Exported String; unset by default | Optional `initServer.sqf` value | Imports the catalogue string at economy start. |
| `call Waldo_fnc_EcoCore_isActive` | No arguments | Script that needs to wait for economy startup | Returns a Boolean on the calling machine. |

These tools do not take a map marker or a `CfgVehicles` classname. World
placement belongs to the Resource, Research, Build and Buy guides. Ground
Command permissions follow the current player connection, so set them in a
running mission. The server owns economy state and supplies it to JIP players.

## Ground Command

By default, any player on a side can spend that side's resources. **Ground Command** lets you restrict that to trusted players: designate someone as Ground Command and only they (and Zeus) may spend resources, order research, and manage/upgrade buildings for the side. This gives you a clear commander role without locking everyone else out of the rest of the game.

Assign it live in Zeus: **WMP Economy Systems → Ground Command**, then pick the player(s).

> Ground Command is **Zeus-only**. Its permission keys are tied to a player's current connection, so assign it after the mission starts.

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

Three bundled presets provide economies of increasing complexity, from **LOW** (a single resource and research) to **HIGH** (a larger linked economy). Apply one from the Zeus preset menu, through `Waldo_Economy_Preset`, or with a preset composition. Faction catalogues (`NATO`, `CSAT`, `AAF`, `SYNDIKAT`) set each side's purchasable vehicles.

## Purge

**Purge** removes the economy suite from the running mission. It deletes its world objects and markers and stops its loops. Purge is **permanent for that mission**: it also prevents joining (JIP) players from re-initialising the suite. Restart the mission to run the economy again.

## Status check (for scripters)

`call Waldo_fnc_EcoCore_isActive` returns whether the suite is currently running, so you can gate dependent scripts, e.g. `waitUntil { call Waldo_fnc_EcoCore_isActive };`. Failed player actions (not enough resources, unmet requirements, no drop point in range) use a branded timed notice instead of silently failing or burying the reason in game chat.

## If a commander cannot order

Assign Ground Command to the player's current connection in Zeus, then check the side and target catalogue. An editor-placed unit name cannot pre-grant this live permission. After **Purge**, restart the mission before expecting any economy operation to work again.

## See also

* [Setup & Configuration](Waldos-Economy-Systems-Setup-And-Configuration)
* [Waldos Economy Systems hub](Waldos-Economy-Systems)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)

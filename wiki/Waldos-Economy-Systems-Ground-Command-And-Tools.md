_Associated Files: MissionScripts\EconomySystems\Command\ (`Waldo_fnc_EcoCommand_*`), MissionScripts\EconomySystems\Core\ (`Waldo_fnc_EcoCore_*`)_

Alongside the four economy systems, [Waldos Economy Systems](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Economy-Systems) ships several management tools, all reached from the **Waldos Economy Systems** menu in Zeus.

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

The **Export** tool serialises your *entire* configuration — resources, research, buildings, purchases — into a single text string. **Import** loads it back. Use this to:

* save a configuration you built live in Zeus,
* share a configuration between missions, or
* bake it into a mission via `Waldo_Economy_ConfigString` (see [Setup & Configuration](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Economy-Systems-Setup-And-Configuration)).

The recommended workflow is **build it in Zeus once, Export, then paste the string into `initServer.sqf`** so it loads automatically every time.

## Presets

Three bundled presets give you a ready-made economy at increasing complexity — **LOW** (a single resource and research) through **HIGH** (a deep, interlocking economy). Apply one from the Zeus preset menu, from `Waldo_Economy_Preset`, or by dropping a preset composition. Faction catalogues (`NATO`, `CSAT`, `AAF`, `SYNDIKAT`) tailor each side's purchasable vehicles.

## Purge

**Purge** cleanly removes the entire economy suite from the running mission — deletes its world objects and markers and stops its loops — if you decide you no longer want it.

## See also

* [Setup & Configuration](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Economy-Systems-Setup-And-Configuration)
* [Waldos Economy Systems hub](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Economy-Systems)

# Persistence

> **Use this page when:** you want player state or specific placed objects to survive disconnects and mission restarts through a database.

_Associated Files: `MissionConfig/persistenceConfig.sqf`, `MissionScripts/Persistence/`; `initServer.sqf` (database authority startup), `initPlayerLocal.sqf` (per-player capture/apply)_

Persistence saves and restores player state — and specific, explicitly registered world objects — across a real database, backed by the [INIDBI2](https://github.com/SzwedzikPL/inidbi2) extension. It is off by default and stays off unless both the mission maker enables it **and** the server can prove a working INIDBI2 runtime is actually loaded, not just declared as a dependency. Database access is always server-only; each client only captures and applies its own state.

## Beginner quick start

1. Install the INIDBI2 extension on the **server** (not required on clients) — see its own release for that step; WMP does not bundle it.
2. Open `MissionConfig\persistenceConfig.sqf` and set `Waldo_Persistence_Enable` to `true`.
3. Launch the mission on a server that has INIDBI2 installed. The server probes for a real, loaded extension (not just a declared dependency) and disables itself cleanly if the probe fails — check the RPT for `[WMP DIAG]` persistence lines if nothing is saving.
4. Play, disconnect and reconnect (or use `Waldo_fnc_PersistenceStop` then restart the mission) to confirm loadout/medical state is restored.

The `[WMP]Persistence_Object_Example_Minimal` and `[WMP]Persistence_Object_Example_Full` compositions demonstrate registering a placed object (see below) without any scripting beyond the object's own init field.

## What gets saved

Player persistence can independently save loadout, ACE medical state, food/water, position and supported radio state. Loadout and medical state are enabled by default; the more mission-sensitive fields are not. The server starts the database branch from `initServer.sqf`; each player starts only capture/apply work from `initPlayerLocal.sqf`.

| Setting | Default | Purpose |
|---|---|---|
| `Waldo_Persistence_Enable` | `false` | Master opt-in; requires a working server INIDBI2 extension |
| `Waldo_Persistence_SaveLoadout` | `true` | Filtered inventory (unique ACRE radio IDs stripped) |
| `Waldo_Persistence_SaveMedical` | `true` | ACE medical state |
| `Waldo_Persistence_SaveFoodWater` | `false` | Hunger/thirst state |
| `Waldo_Persistence_SavePosition` | `false` | Off by default — can bypass mission flow (e.g. skip an intro area) |
| `Waldo_Persistence_SaveRadios` | `false` | Per-player ACRE channel/spatial state |
| `Waldo_Persistence_Scope` | `"MISSION"` | `"MISSION"` isolates records by mission+terrain; `"CAMPAIGN"` shares by database name across missions |
| `Waldo_Persistence_DatabaseName` | `"WaldosMissionPack"` | Database identity; only matters when `Scope` is `"CAMPAIGN"` |
| `Waldo_Persistence_PlayerSaveInterval` | `60` | ADVANCED — seconds between automatic player writes; lower increases server I/O |
| `Waldo_Persistence_ObjectSaveInterval` | `60` | ADVANCED — seconds between registered-world-object writes |
| `Waldo_Persistence_DefaultCustomVariables` | `[]` | Extra variable names saved alongside the built-in fields — see [Optional Feature Extensions](Optional-Feature-Extensions#persistence-interoperability) |

Tune the shared `Waldo_Persistence_*` values in `MissionConfig\persistenceConfig.sqf`.

Player records are separated by Steam UID and, by default, database name + mission name + terrain. Keep `Waldo_Persistence_Scope = "MISSION"` for ordinary missions. Use `"CAMPAIGN"` only when several missions using the same `Waldo_Persistence_DatabaseName` intentionally share progress. The server validates the identity stored inside a record before sending it to a client.

ACRE-aware persistence filters unique `_ID_n` radio classes before storage. When `Waldo_Persistence_SaveRadios` is enabled, channel and spatial state are stored separately by base radio class and same-type ordinal. A restore creates fresh unique radios first and then reapplies persisted state; when disabled, the current side/group mission plan is applied instead. ACRE being absent leaves ordinary loadouts unchanged.

## Registering objects — `Waldo_fnc_PersistenceRegisterObject`

Register an editor object from `initServer.sqf` or its own init field:

```sqf
[supplyCrate, "base_supply_1", [true, false, false, false, false]] call Waldo_fnc_PersistenceRegisterObject;
// [object, key, [cargo, damage, fuel, ammo/pylons, position, customVariableNames]]
```

| Argument | Type | Meaning |
|---|---|---|
| `object` | Object | The thing to persist |
| `key` | String | Stable, unique within the mission. Letters/digits/underscore/dash only — anything else is rejected (logged) rather than silently mangled |
| `options[0..4]` | Bool (each) | Save cargo / damage / fuel / ammunition-pylons / position. Missing values default `true`, so a bare `[obj, "key"]` call saves everything |
| `options[5]` | Array\<String\> | Extra serialisable variable names, beyond the five built-in fields. Defaults to `Waldo_Persistence_DefaultCustomVariables` when omitted — see [Optional Feature Extensions](Optional-Feature-Extensions#persistence-interoperability) |

Registering the **same key again** (a re-run init field, or using the ZEN module twice near the same object) **replaces** the previous entry rather than duplicating it — safe to call more than once. Registrations made while the database is still starting are queued by key and replayed once it's ready.

**Calling contract.** This function is stricter than most WMP "no `isServer` wrapper needed" calls (`Waldo_fnc_Jammer`, `Waldo_fnc_HazardRegisterPresetZone`, ...), which self-forward to the server with `remoteExecCall` when invoked from a client — this one does **not** forward itself, and a client `remoteExecCall` is rejected outright. It only works:
- from an object's own **Eden init field** (which runs identically on every machine; only the server's own execution of that line actually registers anything — that's what "no wrapper needed" means here, not "safe to `remoteExecCall`"), or
- from a **direct `call`/`spawn`** by code already running on the server (`initServer.sqf`, another server-only script, or a server-side handler — see how the ZEN module below reaches it).

A mission-specific curator/client-triggered registration flow needs its own authenticated server-side bridge mirroring that pattern; it must not `remoteExecCall` this function directly.

Call `Waldo_fnc_PersistenceStop` to save registered objects and stop the system without deleting its database.

## Zeus modules

Under **WMP Mission Tools**, three focused modules cover runtime control without any scripting:

- **Persistence - Control** enables or disables persistence and configures player/object save intervals and the supported data categories. Enabling still requires a compatible INIDBI2 server runtime; placing the module does not silently bypass the dependency gate.
- **Persistence - Register Object** selects the nearest object within 25 metres and registers its cargo, damage, fuel, ammunition/pylons and/or transform under an automatically generated stable runtime key.
- **Persistence - Save Now** can immediately request saves from connected players, registered objects, or both without disabling the system.

## Interoperability and extension

Registered objects can persist an allow-list of custom variables in addition to cargo, damage, fuel, ammunition and position. Pass variable names as the sixth registration option, or edit `Waldo_Persistence_DefaultCustomVariables`. Object scale, breach state and stable field-resupply state are included by default. Existing version-one object records remain loadable.

Dynamic objects are not recreated automatically. Register stable editor objects with unique keys; use mission-specific recreation logic for objects that do not exist when a save is loaded.

## See also

- [Optional Feature Systems](Optional-Feature-Systems)
- [Optional Feature Extensions](Optional-Feature-Extensions)
- [Waldos Mission Pack Zeus Modules](Waldos-Mission-Pack-Zeus-Modules)
- [Mission Diagnostics](Mission-Diagnostics)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)

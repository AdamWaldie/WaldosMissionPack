# Persistence

> **Use this page when:** you want player state or specific placed objects to survive disconnects and mission restarts through a database.

_Associated Files: `MissionConfig/persistenceConfig.sqf`, `MissionScripts/Persistence/`; `initServer.sqf` (database authority startup), `initPlayerLocal.sqf` (per-player capture/apply)_

Persistence saves player state and registered world objects in an [INIDBI2](https://github.com/SzwedzikPL/inidbi2) database. It is off by default. To use it, enable the WMP setting and install a working INIDBI2 runtime on the server. The server handles database access. Each client captures and applies only its own player state.

## Quick start

1. Install the INIDBI2 extension on the **server**. Clients do not need it. Follow the extension's own installation instructions; WMP does not bundle it.
2. Open `MissionConfig\persistenceConfig.sqf` and set `Waldo_Persistence_Enable` to `true`.
3. Launch the mission on that server. WMP checks that the extension is loaded and working. If the check fails, persistence stays off. Check the RPT for `[WMP DIAG]` persistence lines if saves do not appear.
4. Play long enough for a save, disconnect, and reconnect to confirm your loadout or medical state returns. For a deliberate save before reconnecting, use the **Persistence - Save Now** Zeus module. Stopping persistence is not a substitute for saving every player's current state.

The `[WMP]Persistence_Object_Example_Minimal` and `[WMP]Persistence_Object_Example_Full` compositions demonstrate registering a placed object (see below) without any scripting beyond the object's own init field.

## Settings and saved data

Player persistence can save loadout, ACE medical state, food and water, position, and supported radio state independently. Loadout and medical state are on by default. The server starts database work from `initServer.sqf`. Each player starts local capture and restore work from `initPlayerLocal.sqf`.

| Setting | Type | Default | Purpose |
|---|---|---|---|
| `Waldo_Persistence_Enable` | Boolean | `false` | Enable persistence if server INIDBI2 is ready |
| `Waldo_Persistence_SaveLoadout` | Boolean | `true` | Save filtered inventory, without unique ACRE radio IDs |
| `Waldo_Persistence_SaveMedical` | Boolean | `true` | Save ACE medical state |
| `Waldo_Persistence_SaveFoodWater` | Boolean | `false` | Save supported hunger and thirst state |
| `Waldo_Persistence_SavePosition` | Boolean | `false` | Save position. This can bypass an intro or staging area |
| `Waldo_Persistence_SaveRadios` | Boolean | `false` | Save supported per-player ACRE radio state |
| `Waldo_Persistence_Scope` | String enum | `"MISSION"` | `"MISSION"` isolates by mission and terrain. `"CAMPAIGN"` shares records by database name |
| `Waldo_Persistence_DatabaseName` | String | `"WaldosMissionPack"` | Save collection name. Changing it selects different records |
| `Waldo_Persistence_PlayerSaveInterval` | Number (seconds) | `60` | Time between automatic player writes; shorter means more server I/O |
| `Waldo_Persistence_ObjectSaveInterval` | Number (seconds) | `60` | Time between automatic writes for registered objects |
| `Waldo_Persistence_DefaultCustomVariables` | Array of Strings | Seven WMP variable names | Default names to save for registered objects; see below |

The seven default custom variables are `Waldo_ObjectScale`, `Waldo_ObjectScaleOriginal`, `Waldo_Breaching_Processed`, `Waldo_Breaching_AccumulatedStrength`, `Waldo_FieldResupply_Hub`, `Waldo_FieldResupply_Stock`, and `Waldo_FieldResupply_Deployed`. See [Optional Feature Extensions](Optional-Feature-Extensions#persistence-interoperability) before adding your own.

Tune the shared `Waldo_Persistence_*` values in `MissionConfig\persistenceConfig.sqf`.

Player records are separated by Steam UID and, by default, database name + mission name + terrain. Keep `Waldo_Persistence_Scope = "MISSION"` for ordinary missions. Use `"CAMPAIGN"` only when several missions using the same `Waldo_Persistence_DatabaseName` intentionally share progress. The server validates the identity stored inside a record before sending it to a client.

ACRE-aware persistence filters unique `_ID_n` radio classes before storage. When `Waldo_Persistence_SaveRadios` is enabled, it saves channel and spatial state separately by base radio class and same-type ordinal. Restore creates fresh unique radios, then applies saved settings. With SaveRadios off, WMP applies the current side or group radio plan. Ordinary loadouts work without ACRE.

## Call: register objects with `Waldo_fnc_PersistenceRegisterObject`

Register an editor object from `initServer.sqf` or its own init field:

```sqf
[supplyCrate, "base_supply_1", [true, false, false, false, false]] call Waldo_fnc_PersistenceRegisterObject;
// [object, key, [cargo, damage, fuel, ammo/pylons, position, customVariableNames]]
```

| Argument | Type | Meaning |
|---|---|---|
| `object` | Object | The thing to persist |
| `key` | String | Stable and unique within the mission. Use letters, digits, underscores or dashes. Other characters cause rejection and an RPT entry |
| `options[0..4]` | Bool (each) | Save cargo / damage / fuel / ammunition-pylons / position. Missing values default `true`, so a bare `[obj, "key"]` call saves everything |
| `options[5]` | Array\<String\> | Extra serialisable variable names. Defaults to `Waldo_Persistence_DefaultCustomVariables` when omitted. See [Optional Feature Extensions](Optional-Feature-Extensions#persistence-interoperability) |

The call returns a Boolean: `true` when the server registers or queues the object, `false` when persistence is off, the object or key is invalid, or the call reaches the wrong machine. Because an Eden init field also runs on clients, its client-side copies return `false`; the server's copy is the one that matters. Do not treat a client-side return value as proof that server registration failed.

Registering the **same key again** replaces its previous entry. You can rerun an init field without creating duplicates. While the database starts, WMP queues registrations by key and applies them when ready.

**Calling contract.** This function does not forward client calls to the server. A client `remoteExecCall` to it is rejected. Call it in one of these places:

- An object's **Eden init field**. The field runs on all machines, but only its server execution registers the object. No `isServer` wrapper is needed.
- Code already running on the server, such as `initServer.sqf` or a server-side handler. Use a direct `call` or `spawn`.

A custom curator or client registration flow needs an authenticated server-side handler. Do not send `remoteExecCall` directly to this function.

`[] call Waldo_fnc_PersistenceStop` takes no mission-maker arguments and returns nothing. It saves registered objects, stops the server and client loops, and keeps existing database records. It does **not** request a final fresh save of every player's state. Use **Persistence - Save Now** before stopping if that is needed.

## Zeus modules

Under **WMP Mission Tools**, three focused modules cover runtime control without any scripting:

- **Persistence - Control** enables or disables persistence and configures player/object save intervals and the supported data categories. Enabling still requires a compatible INIDBI2 server runtime; placing the module does not silently bypass the dependency gate.
- **Persistence - Register Object** selects the nearest object within 25 metres and registers its cargo, damage, fuel, ammunition/pylons and/or transform under an automatically generated stable runtime key.
- **Persistence - Save Now** can immediately request saves from connected players, registered objects, or both without disabling the system.

## Interoperability and extension

Registered objects can persist an allow-list of custom variables in addition to cargo, damage, fuel, ammunition and position. Pass variable names as the sixth registration option, or edit `Waldo_Persistence_DefaultCustomVariables`. Object scale, breach state and stable field-resupply state are included by default. Existing version-one object records remain loadable.

Dynamic objects are not recreated automatically. Register stable editor objects with unique keys; use mission-specific recreation logic for objects that do not exist when a save is loaded.

## If nothing is restored

Check that INIDBI2 is available on the server, persistence is enabled, and the object has a stable registration key. A dynamically spawned object must be recreated by your mission before its saved state can be applied; registration alone does not respawn it. Test a save and a fresh server start before relying on it in an event.

## See also

- [Optional Feature Systems](Optional-Feature-Systems)
- [Optional Feature Extensions](Optional-Feature-Extensions)
- [Waldos Mission Pack Zeus Modules](Waldos-Mission-Pack-Zeus-Modules)
- [Mission Diagnostics](Mission-Diagnostics)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)

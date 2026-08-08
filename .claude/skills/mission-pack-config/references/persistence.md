# INIDBI2 persistence

Optional player and registered-object persistence. Requires the INIDBI2
extension available server-side — if unavailable, WMP disables persistence
cleanly rather than erroring. "Automatic + dependency gate" pattern.

## Config (`MissionConfig\persistenceConfig.sqf` — shared)

```sqf
["Waldo_Persistence_Enable", false],              // requires a working server INIDBI2 extension
["Waldo_Persistence_SaveLoadout", true],          // filters unique ACRE IDs, restores ordinary inventory
["Waldo_Persistence_SaveMedical", true],          // supported ACE medical state
["Waldo_Persistence_SaveFoodWater", false],
["Waldo_Persistence_SavePosition", false],        // may bypass mission progression — off by default deliberately
["Waldo_Persistence_SaveRadios", false],          // per-player radio state, see acre2.md
["Waldo_Persistence_DatabaseName", "WaldosMissionPack"],
["Waldo_Persistence_Scope", "MISSION"],           // MISSION isolates by db+mission+terrain; CAMPAIGN deliberately shares
["Waldo_Persistence_PlayerSaveInterval", 60],     // ADVANCED, seconds
["Waldo_Persistence_ObjectSaveInterval", 60],     // ADVANCED, seconds
["Waldo_Persistence_DefaultCustomVariables", [ /* extra serialisable object-variable names copied by default */ ]]
```

## Normal standalone-mission example

```sqf
["Waldo_Persistence_DatabaseName", "Operation_Nightjar"],
["Waldo_Persistence_Scope", "MISSION"]
```

Use `"CAMPAIGN"` only when several missions sharing the same
`Waldo_Persistence_DatabaseName` should intentionally share player progress.
The server validates the identity stored inside a record before sending it
to a client, and binds each record to the requesting Steam UID.

## Registering a persistent object (`initServer.sqf` or object init) — `Waldo_fnc_PersistenceRegisterObject`

```sqf
[supplyCrate, "base_supply_1", [true, false, false, false, false]]
    call Waldo_fnc_PersistenceRegisterObject;
// [object, key, [cargo, damage, fuel, ammo/pylons, position, customVariableNames]]
```

Params, in order: `object` (the thing to persist), `key` (STRING, stable and
unique within the mission — letters/digits/underscore/dash only; anything
else is rejected and logged, not silently mangled), then an `options` ARRAY
of `[cargo, damage, fuel, ammo/pylons, position, customVariableNames]`. The
first five are booleans and default `true` when omitted/`nil` (so a bare
`[obj, "key"]` call saves everything); the 6th is an ARRAY of extra
serialisable variable names and defaults to
`Waldo_Persistence_DefaultCustomVariables` when omitted — see
`wiki/Optional-Feature-Extensions.md` for that field's exact shape.

**Calling contract — read this before wiring a new entry point.** Unlike
most WMP "no `isServer` wrapper needed" functions (`Waldo_fnc_Jammer`,
`Waldo_fnc_HazardRegisterPresetZone`, ...), which self-forward to the
server with `remoteExecCall` when called from a client, this one does
**not** forward itself — a client `remoteExecCall` is rejected outright
(`remoteExecutedOwner > 0` guard). It only works:
- from an object's own **Eden init field** (runs identically on every
  machine; only the server's own execution of that line does anything —
  that is what "no wrapper needed" means here, not "safe to remoteExec"), or
- from a **direct `call`/`spawn`** by code already running on the server
  (`initServer.sqf`, another server-only script, or a server-side handler
  like the ZEN module below).

A mission-specific curator/client-triggered registration flow needs its own
authenticated server-side bridge (mirroring the ZEN module's pattern) — it
must not `remoteExecCall` this function directly.

Registering the same key again (re-run init field, ZEN module used twice on
the same object) **replaces** the previous entry rather than duplicating it
— safe to call more than once. Registrations made while the database is
still starting are queued by key and replayed once it's ready.
`Waldo_fnc_PersistenceStop` saves registered objects and stops the system
without deleting its database. Dynamic objects are **not** recreated
automatically — register stable editor objects with unique keys; write
mission-specific recreation logic for objects that don't exist when a save
loads.

### Eden composition (beginner drop-in)

`WMP_Compositions/[WMP]Persistence_Object_Example_Minimal` registers a
crate with only a stable key and the object itself — no options array, so
every field (cargo/damage/fuel/ammo/position) saves by default. `_Full`
shows the options array explicitly, registering only cargo and position.
Either way the object does nothing until `Waldo_Persistence_Enable` is
`true` and a working server INIDBI2 extension is detected (see Config
above).

## Zeus

**Persistence - Control** (start/reconfigure/stop), **Persistence -
Register Object** (assign a nearby object's stable key/saved fields during
play), **Persistence - Save Now** (immediate capture from connected players
+ registered objects, without stopping persistence; reports cleanly if
INIDBI2 isn't active).

## Gotchas

- Database access remains server-only; `initServer.sqf` starts the database
  branch, each player's `initPlayerLocal.sqf` starts only capture/apply work.
- ACRE-aware: unique `_ID_n` radio classes are filtered before storage, see
  `acre2.md`'s "Loadout saving and respawn" section for the exact
  interaction between this and normal respawn saving.

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

## Registering a persistent object (`initServer.sqf` or object init)

```sqf
[supplyCrate, "base_supply_1", [true, false, false, false, false]]
    call Waldo_fnc_PersistenceRegisterObject;
```

The five booleans: cargo, damage, fuel, ammunition/pylons, position. Keys
must be stable and unique. Registrations made while the database is still
starting are queued. `Waldo_fnc_PersistenceStop` saves registered objects
and stops the system without deleting its database. Dynamic objects are
**not** recreated automatically — register stable editor objects with
unique keys; write mission-specific recreation logic for objects that don't
exist when a save loads.

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

# Loadout & logistics system

This is the foundation almost everything else depends on — configure it
first, or at least understand it before touching ACRE2, crates, or Zeus
logistics modules.

## How it works

`initServer.sqf` scans **every playable unit placed in Eden Editor**
(`Waldo_fnc_SideBaseLoadoutSetup`) by reading `mission.sqm`, extracts
weapons/ammo/clothing/items, deduplicates, and stores the result globally per
side: `Logi_MissionSQMArray_West/East/Ind/Civ`. These arrays power supply
crate contents, limited ACE arsenals, and Zeus logistics modules.

## The one rule mission makers must follow

**Unit loadouts must be edited using ACE Arsenal in Eden Editor.** Vanilla
default loadouts produce empty or incomplete crates — this is the single
most common WMP support question. If a user says crates are empty, this is
the first thing to check (that, and whether Binarize is disabled).

**Mission Binarization must be disabled**: right-click the mission in the
editor → Properties → uncheck Binarize. Without this, `mission.sqm` isn't
readable as text and the whole scan silently produces nothing. Both of these
are Eden Editor GUI steps — instruction mode, never something you do
directly, and never something achieved by editing `mission.sqm`.

## Config (`MissionConfig\logisticsConfig.sqf`)

```sqf
["Logi_SupplyBoxClass", "B_supplyCrate_F", true],               // server entry, JIP-published
["Logi_MedicalBoxClass", "ACE_medicalSupplyCrate_advanced", true] // defaults to ACE advanced crate if ACE Medical is loaded, IDAP crate otherwise
```

These are `server` entries loaded by `initServer.sqf` — edit the config
file, don't paste `setVariable` calls into `initServer.sqf` yourself. They
just set the classnames used when supply/medical crates are spawned (by Zeus
modules or scripts) — swap in whatever crate object the mission uses.

This same file also carries Field Resupply, Vehicle Recovery, Transport
Services and Object Scaling settings — see `field-resupply.md`,
`vehicle-recovery-rallies.md`, `transport-services.md` and
`object-scaling.md` respectively.

## TFAR note

`missionFileLookup.sqf` also reads the `radio` inventory slot from
`mission.sqm`, so TFAR radios placed via Eden's native radio assignment flow
in the loadout automatically end up in supply crates too, with no extra
config.

## Standalone Quartermaster access point

The simple always-available way to give players a retrieval point without a
full MHQ. One call in any object/NPC's Eden init field:

```sqf
[this] call Waldo_fnc_SetupQuarterMaster;
// or with spawn placement: [target, spawn bearing, spawn distance, deployment controlled]
[this, 180, 4] call Waldo_fnc_SetupQuarterMaster;
```

Safe to leave directly in an object's init field — no `isServer` wrapper
needed, it publishes standalone availability itself. Installs ACE
interaction actions (Medical/Ammo/Supply Box, Spare Track, Spare Wheel),
with vanilla `addAction` fallback when ACE is absent. Crate requests are
always validated and spawned server-side through
`Waldo_fnc_LogisticsSpawner`. The fourth argument (`deploymentControlled`)
is for systems that own their own deploy state, like the MHQ — normal
mission makers should leave it `false`/omitted. See
`wiki/Logistics-System,-Starter-Crates-And-Quartermaster.md` for the full
walkthrough.

### Eden composition (beginner drop-in)

`WMP_Compositions/[WMP]Logistics_Spawner_Example_Minimal` is a pre-placed
point with just `[this] call Waldo_fnc_SetupQuarterMaster;`. `_Full` shows
the spawn-bearing/spawn-distance arguments set explicitly on the same
point, immediately active as a standalone quartermaster.

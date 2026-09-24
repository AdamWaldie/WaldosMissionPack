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

This same file also carries Quartermaster (below), Supply Transfers,
Physical Cargo, Field Resupply, Vehicle Recovery, Transport
Services and Object Scaling settings — see `supply-transfers.md`,
`physical-cargo.md`, `field-resupply.md`,
`vehicle-recovery-rallies.md`, `transport-services.md` and
`object-scaling.md` respectively.

## TFAR note

`missionFileLookup.sqf` also reads the `radio` inventory slot from
`mission.sqm`, so TFAR radios placed via Eden's native radio assignment flow
in the loadout automatically end up in supply crates too, with no extra
config.

## Quartermaster (`MissionConfig\logisticsConfig.sqf`)

The Quartermaster is an object or NPC where players request supply boxes,
spare parts, rearm and fuel sources. One call in any object/NPC's Eden
init field:

```sqf
[this] call Waldo_fnc_SetupQuarterMaster;
// [target, spawn bearing (default 90), spawn distance (default 2), deployment controlled (default false)]
[this, 180, 4] call Waldo_fnc_SetupQuarterMaster;   // crates spawn 4 m behind the object
```

Safe to leave directly in an object's init field — **no `isServer`
wrapper**. Bearing is relative to the object (`0` front, `90` right, `180`
rear, `270` left). The fourth argument (`deploymentControlled`) is for
systems that own their own deploy state, like the MHQ — normal mission
makers leave it `false`/omitted; `true` hides retrieval until another
server-owned system activates the point.

Every point has a WMP-blue **Quartermaster** informational action. With ACE,
retrieval is under **ACE Interact > Quartermaster** (grouped into infantry
supplies, vehicle support and fuel); without ACE the choices appear in the
vanilla action menu. Standalone points show an object-following 3D
**Quartermaster** label (`Waldo_QM_Marker_Enable`). Requests are validated
and spawned server-side; the progress bar lasts five seconds and the spawned
object's ACE cargo name carries the issue label.

### Issue types — all ten on by default

| ACE action | Contents | Flag / class / quantity keys |
|---|---|---|
| Medical Box | ACE medical supplies (vanilla if no ACE Medical); marked as field hospital | `Waldo_QM_Medical_Enable`, `Waldo_QM_Medical_CrateClass` (`""` = follow `Logi_MedicalBoxClass`) |
| Heavy Supply Box | Full side complement from mission loadouts | `Waldo_QM_Supply_Enable`, `Waldo_QM_Supply_CrateClass` (`"B_supplyCrate_F"`) |
| Ammo Box | Ammo only (0.75× scale) | `Waldo_QM_Ammo_Enable`, `Waldo_QM_Ammo_CrateClass` (`"B_supplyCrate_F"`) |
| ACE Wheel / ACE Track | Spare `ACE_Wheel` / `ACE_Track` | `Waldo_QM_Wheel_Enable`, `Waldo_QM_Track_Enable` |
| Grenades Box | Throwables from this side's playable loadouts | `Waldo_QM_Grenades_Enable`, `Waldo_QM_Grenades_CrateClass` (`"Box_NATO_Ammo_F"`), `Waldo_QM_Grenades_CountPerType` (20) |
| Explosives Box | Mines/charges from this side's playable loadouts | `Waldo_QM_Explosives_Enable`, `Waldo_QM_Explosives_CrateClass` (`"Box_NATO_AmmoOrd_F"`), `Waldo_QM_Explosives_CountPerType` (8) |
| Rearm Box | Empty box acting as an ACE rearm source (vehicles and statics) | `Waldo_QM_Rearm_Enable`, `Waldo_QM_Rearm_CrateClass` (`"Box_NATO_AmmoVeh_F"`), `Waldo_QM_Rearm_Supply` (1200) |
| Fuel Barrel / Fuel Jerrycan | ACE fuel sources | `Waldo_QM_FuelBarrel_Enable`/`_Litres` (200), `Waldo_QM_FuelJerrycan_Enable`/`_Litres` (20) |

`Waldo_Quartermaster_Enable` (default `true`) gates the whole action set.
Issue flags are **global ceilings** — a ZEN point can offer fewer, never
more. WMP rejects unavailable crate classes.

**Rearm Box and ACE's Rearm supply mode** (WMP never changes the mission's
ACE mode): in **Limited** (`ace_rearm_supply = 1`) each box holds
`Waldo_QM_Rearm_Supply` points and its status action counts down to
**Rearm supply exhausted**; **Unlimited** ignores the value; **Specific
Magazines** mode makes the empty Rearm Box issue unavailable — set the ACE
mode in addon settings before relying on it.

COMPATIBILITY keys, leave alone: `Waldo_QM_VehicleRearm_Enable`/
`Waldo_QM_StaticRearm_Enable` (default `false`; both alias the single Rearm
Box), their `_CrateClass` and `_Supply` (1200 / 250) rows for direct legacy
scripted calls.

The five established issues (medical/supply/ammo/wheel/track) block
duplicates within 5 m of the spawn point; the five newer issues rely on
clear-space placement instead.

### Zeus: Quartermaster - Set Up Object (WMP Logistics)

Place directly on the intended object. Sets spawn bearing (0–359), distance
(2–12 m), **Deployment controlled** (leave unchecked for a standalone
laptop) and which enabled issues this point offers. ZEN remembers settings
when re-editing the same point.

### Interaction with the newer crate features

With `Waldo_SupplyTransfers_Enable` on, quartermaster-issued crates register
for Supply Transfers automatically (`supply-transfers.md`). All WMP-issued
inventory crates get ACE Drag/Carry on spawn regardless, and are eligible
for Physical Cargo mounting (`physical-cargo.md`). Starter crates are
excluded from both. See
`wiki/Logistics-System,-Starter-Crates-And-Quartermaster.md` for the full
walkthrough.

### Eden composition (beginner drop-in)

**[WMP] Quartermaster (Minimal)** (source folder still
`WMP_Compositions/[WMP]Logistics_Spawner_Example_Minimal` for
compatibility) is a pre-placed point with just
`[this] call Waldo_fnc_SetupQuarterMaster;`. **Quartermaster (Full)**
(`..._Full`) shows spawn bearing, distance and deployment control set
explicitly. Issue flags are still set mission-wide in `logisticsConfig.sqf`.

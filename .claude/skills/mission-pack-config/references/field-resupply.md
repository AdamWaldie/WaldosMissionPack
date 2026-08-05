# Field resupply

Finite-resource ammunition system: a hub refills carrier crate allowances,
carriers deploy charge-limited crates, players take validated magazine
types, crates can be salvaged. "Register" pattern.

## Config (`MissionConfig\logisticsConfig.sqf` — shared)

```sqf
["Waldo_FieldResupply_Enable", false],
["Waldo_FieldResupply_CrateClass", "Box_NATO_Ammo_F"],
["Waldo_FieldResupply_DefaultCarrierCapacity", 2],       // crates a carrier can hold
["Waldo_FieldResupply_ChargesPerCrate", 5],              // resupply uses per deployed crate
["Waldo_FieldResupply_MagazinesPerType", 1],             // fixed count per type when capacity mode is off
["Waldo_FieldResupply_UseCapacityBasedAmounts", true],   // false = always use MagazinesPerType
["Waldo_FieldResupply_CapacityAmounts", [ /* per magazine-capacity band */ ]],
["Waldo_FieldResupply_MinimumMagazineRounds", 2],        // excludes grenades/single-round ordnance by default
["Waldo_FieldResupply_AllowedMagazines", []],            // [] discovers carried types
["Waldo_FieldResupply_BlockedMagazines", []],            // wins over allowlist
["Waldo_FieldResupply_RetainOnRespawn", true]
```

Capacity-based amounts default to 4 magazines up to 4-round capacity, 3 up
to 10, 8 up to 40, 3 up to 70, 2 above 70 — replace those five bands or
switch to a fixed `MagazinesPerType` amount.

## Registering (`initServer.sqf`)

```sqf
if (isServer) then {
    [supplyHub, west, -1] call Waldo_fnc_FieldResupplyRegisterHub;       // -1 = unlimited hub stock
    [mule, 3, 3] call Waldo_fnc_FieldResupplyAssignCarrier;
};
```

Granting crates directly (e.g. as a reward):

```sqf
[_carrier, _amount, _expandCapacity] call Waldo_fnc_FieldResupplyGrantCrates;
```

`_expandCapacity` default `false` clamps the grant to spare capacity;
`true` raises capacity to fit the whole grant.

## Player usage

**Field Resupply** category on the carrier, hub or deployed crate: assigned
carriers wearing a backpack get **Check Resupply Crates** and **Deploy Field
Resupply** (foot-only). A deployed crate derives logical supply rows from
the carrier's compatible loaded/carried magazines but keeps its physical
inventory empty so ACE Gear can't bypass charge consumption.

## Zeus

Focused modules register a nearby hub, assign a nearby carrier, or grant
additional portable crates during play.

## Gotchas

- Does not guess vehicle-ammunition compatibility or manufacture mod ammo
  outside the configured rules.
- Removing a partly consumed crate recovers no portable crate — only unused
  crates can be recovered by a carrier.

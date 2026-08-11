# Field resupply

Finite-resource ammunition system: a hub refills carrier crate allowances,
carriers deploy a real populated crate for others, players take from it
through ordinary ACE Cargo/Gear interaction, and unused crates can be
salvaged. "Register" pattern. A deployed crate is populated exactly like a
standard supply crate (`Waldo_fnc_SupplyCratePopulate`), scoped to the
servicing hub's own side — there is no separate charge counter or magazine
allow/block list.

## Config (`MissionConfig\logisticsConfig.sqf` — shared)

```sqf
["Waldo_FieldResupply_Enable", false],
["Waldo_FieldResupply_CrateClass", "Box_NATO_Ammo_F"],
["Waldo_FieldResupply_DefaultCarrierCapacity", 2],           // crates a carrier can hold
["Waldo_FieldResupply_CrateSizeScalar", 1],                  // multiplies populated quantities
["Waldo_FieldResupply_IncludeWeaponsAttachments", false],    // also populate weapons/attachments/clothing
["Waldo_FieldResupply_IncludeLaunchers", false],             // also populate launchers/launcher ammo
["Waldo_FieldResupply_RetainOnRespawn", true]
```

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

**Field Resupply** category on the carrier or deployed crate: assigned
carriers wearing a backpack get **Check Resupply Crates** and **Deploy Field
Resupply** (foot-only). DEPLOY populates a real crate from the side the
carrier last refilled from (or the carrier's own side if never refilled from
a hub) — open its Gear or Cargo to draw supplies, exactly like any other
logistics crate. There is no WMP "take" action.

## Zeus

Focused modules register a nearby hub, assign a nearby carrier, or grant
additional portable crates during play.

## Salvage recoverability

A deployed crate is only recoverable back into the carrier's allowance if
its cargo is unchanged from when it was populated — a crate a player has
already drawn from, or dropped foreign items into, is not salvageable.

## Gotchas

- DEPLOY fails with a clear warning instead of spawning a silently empty
  crate if the servicing side has no scanned playable-unit loadouts.
- Does not guess vehicle-ammunition compatibility or manufacture mod ammo
  outside what the side's own scanned loadouts contain.

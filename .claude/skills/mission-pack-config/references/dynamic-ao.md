# Dynamic AO Generation

Runtime-only, server-authoritative generator for a complete randomized area
of operations without pre-placed compositions or editor modules. One
request can create infantry patrols, building garrisons, manned statics,
weighted ground/air patrols, civilians, parked civilian cars, minefields,
roadblocks and global markers. Configuration is supplied by script or ZEN; there is no separate `MissionConfig` file or enable flag.

## Zeus workflow

**Modules > WMP AI & Combat > Dynamic AO - Create**, placed at the
intended centre. The dialog uses a live combined enemy faction+side
selector (e.g. `[OPFOR] CSAT`) so the two can never contradict each other.
Vehicle/air percentages are relative weights (don't need to total 100);
empty categories fall through to a non-empty category of the selected
faction. Generated units use WMP's active AI profile (see
`ai-rebalance.md`). Dynamic AO has no separate skill slider.

**Dynamic AO - Remove** selects a live AO by friendly name (nearest to the
module is preselected); deleting the AO's invisible centre anchor also
triggers full cleanup. Each generated minefield has its own curator anchor
so it can be removed independently of the rest of the AO.

## Scripted creation

```sqf
private _config = createHashMapFromArray [
    ["id", "AO_NORTH"], ["center", getMarkerPos "ao_north"],
    ["side", east], ["faction", "OPF_F"], ["radius", 700],
    ["patrolGroups", 4], ["garrisonGroups", 6], ["staticTurrets", 2],
    ["vehiclePatrols", 3], ["vehicleMix", [50, 35, 15]],
    ["airPatrols", 1], ["airMix", [50, 20, 20, 10]],
    ["civilianFaction", "CIV_F"], ["civilianPatrols", 10], ["civilianGarrisons", 6], ["civilianCars", 4],
    ["minefields", 2], ["roadblocks", 2], ["showMarker", true]
];
[_config] call Waldo_fnc_DynamicAOCreate;
["AO_NORTH"] call Waldo_fnc_DynamicAODestroy;
["AO_NORTH", 0] call Waldo_fnc_DynamicAODestroyMinefield;
```

An intentional client call supplies the curator player as the second argument.
The server checks that the requester belongs to the sender and has an assigned curator.
A client call without a requester exits without creating anything. Recreating the same `id` safely
replaces the old AO. Key bounds: `radius` 100–2000m, `patrolGroups` 0–12,
`garrisonGroups` 0–30, `staticTurrets` 0–20, `vehiclePatrols`/`airPatrols`
0–10/0–8, `minefields` 0–15, `roadblocks` 0–12. Full table in
`wiki/Dynamic-AO-Generation.md`.

### Eden composition (beginner drop-in)

`WMP_Compositions/[WMP]Dynamic_AO_Example_Minimal` anchors a randomized AO
to a placed object with `id`, `center` and `faction` set (`faction` is required alongside `id`/`center`; omitting
it returns `false` on the server and notifies a supplied requester). `patrolGroups`/`garrisonGroups`
default to a small `3` each, every other category
(static turrets, vehicle/air patrols, civilians, minefields, roadblocks)
defaults to `0`/off. `_Full` shows every category/key explicitly on the
same anchor object.

## Runtime classification (engine inheritance, not a hand-authored pool)

`Waldo_fnc_DynamicAOResolvePools` classifies the selected faction's public
assets automatically: infantry `CAManBase` with a primary weapon or
launcher in config `weapons[]` (handgun-only classes are a logged
fallback when no primary/launcher classes qualify; civilian pools are unfiltered), cars `Car`, APCs/tanks `Tank`
(split by transport capacity), statics `StaticWeapon`, helicopters/planes
`Helicopter`/`Plane`, drones any air asset with `isUav = 1`, jets fixed-wing
≥600km/h max speed. This means Dynamic AO needs **no per-faction content
pool authored anywhere**. Armed officers and pilots remain eligible.
The filter does not check ammunition, vests or backpacks. Combat classes
armed exclusively by later scripts are excluded. Each selected unit is
spawned once; runtime inventory does not prune the cached pool.

## Gotchas

- Patrol, garrison and roadblock requests need an eligible infantry pool.
  Rejection preserves an existing AO with the same id. Set all three counts
  to zero for requests that only need other asset categories.
- Spearhead 1944 US infantry still needs an in-engine retest. Static checks
  do not establish the final mod loadout or headless-client/JIP behaviour.
- Open terrain legitimately produces fewer garrisons/parked cars/roadblocks
  because they need suitable buildings, positions or roads.
- Only the server owns the full registry; clients get a compact JIP-safe
  public summary for the removal dialog/diagnostics.
- Requires Zeus Enhanced for the module UI; the script API itself does not.

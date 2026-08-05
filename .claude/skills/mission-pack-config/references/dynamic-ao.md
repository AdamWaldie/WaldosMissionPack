# Dynamic AO Generation

Runtime-only, server-authoritative generator for a complete randomized area
of operations — no pre-placed compositions or editor modules needed. One
request can create infantry patrols, building garrisons, manned statics,
weighted ground/air patrols, civilians, parked civilian cars, minefields,
roadblocks and global markers. No `MissionConfig` file — purely call/ZEN
driven, and no separate enable flag.

## Zeus workflow

**Modules > WMP Combat Systems > Dynamic AO - Create**, placed at the
intended centre. The dialog uses a live combined enemy faction+side
selector (e.g. `[OPFOR] CSAT`) so the two can never contradict each other.
Vehicle/air percentages are relative weights (don't need to total 100);
empty categories fall through to a non-empty category of the selected
faction. Generated units use WMP's active AI profile (see
`ai-rebalance.md`) — Dynamic AO does not maintain a competing skill slider.

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

A non-server call forwards to the server, but remote player requests are
accepted only from an assigned curator. Recreating the same `id` safely
replaces the old AO. Key bounds: `radius` 100–2000m, `patrolGroups` 0–12,
`garrisonGroups` 0–30, `staticTurrets` 0–20, `vehiclePatrols`/`airPatrols`
0–10/0–8, `minefields` 0–15, `roadblocks` 0–12. Full table in
`wiki/Dynamic-AO-Generation.md`.

## Runtime classification (engine inheritance, not a hand-authored pool)

`Waldo_fnc_DynamicAOResolvePools` classifies the selected faction's public
assets automatically: infantry `CAManBase`, cars `Car`, APCs/tanks `Tank`
(split by transport capacity), statics `StaticWeapon`, helicopters/planes
`Helicopter`/`Plane`, drones any air asset with `isUav = 1`, jets fixed-wing
≥600km/h max speed. This means Dynamic AO needs **no per-faction content
pool authored anywhere** — unlike Dynamic AA/gunship, which do use
mission-authored pools.

## Gotchas

- Open terrain legitimately produces fewer garrisons/parked cars/roadblocks
  (they need suitable buildings/positions/roads) — the generator caps
  rather than fabricating unsuitable locations, this is expected, not a bug.
- Only the server owns the full registry; clients get a compact JIP-safe
  public summary for the removal dialog/diagnostics.
- Requires Zeus Enhanced for the module UI; the script API itself does not.

# Emergency dismount

Local occupant monitor that extracts a player from an overturned or
destroyed land vehicle/boat: chooses a clear nearby position, optionally
preserves velocity, gives a short configurable damage-protection window.
"Automatic" pattern once enabled. Aircraft are excluded by default — general
emergency ejection can't be made safe across every airframe, a mission may
opt in explicitly with a tested profile.

## Config (`MissionConfig\interfaceConfig.sqf` — player local)

```sqf
["Waldo_EmergencyDismount_Enable", false],
["Waldo_EmergencyDismount_OnOverturn", true], ["Waldo_EmergencyDismount_OnDestroyed", true],
["Waldo_EmergencyDismount_PreserveVelocity", true],       // ADVANCED: false is safer, less physical
["Waldo_EmergencyDismount_ProtectDuringExit", true], ["Waldo_EmergencyDismount_ProtectionSeconds", 2],
["Waldo_EmergencyDismount_ClearPositionRadius", 6],
["Waldo_EmergencyDismount_RequireClearExit", false],      // true refuses rather than falling back when no safe point exists
["Waldo_EmergencyDismount_UseEject", false],              // ADVANCED: true uses engine ejection instead of safe move-out
["Waldo_EmergencyDismount_RecoverUnconscious", false],
["Waldo_EmergencyDismount_MinimumOverturnSeconds", 1],    // must persist before the action enables
["Waldo_EmergencyDismount_DamageOnExit", 0],              // fraction 0-1
["Waldo_EmergencyDismount_AllowedKinds", ["LandVehicle", "Ship"]],  // isKindOf roots
["Waldo_EmergencyDismount_VehicleProfiles", createHashMap] // ADVANCED per-class overrides of all the above
```

Start/stop locally with `Waldo_fnc_EmergencyDismountInit` /
`Waldo_fnc_EmergencyDismountStop`. Intentionally **no ZEN module**.

## Bonus: Set Vehicle Upright

Land vehicles also get a local **Set Vehicle Upright** action on the
vehicle itself when tipped and nearly stationary — server validates
proximity, forwards the operation to the vehicle's owning machine, places it
above terrain using real model bounds and the local surface normal. Vehicle
simulation must remain enabled for both this and the extraction mechanics.

## Gotchas

- Per-class `VehicleProfiles` overrides can widen `AllowedKinds` to
  aircraft, but that's an explicit, tested opt-in — don't casually enable it.
- `MinimumOverturnSeconds` prevents a brief roll from triggering extraction.

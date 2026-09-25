# Emergency Dismount

> **Use this page when:** occupants should be extracted from an overturned or destroyed land vehicle or boat.

Emergency Dismount moves an occupant to nearby clear ground and gives them a short damage-protection window. A rollover also gives the occupant a bounded outward and upward velocity based on the flip. It is separate from the action that rights a tipped vehicle.

## Enable and try it

Open `MissionConfig/interfaceConfig.sqf` and change the existing `Waldo_EmergencyDismount_Enable` row from `false` to `true`. Start the mission with a simulation-enabled land vehicle. Roll it with a player inside, or destroy it, and check that the occupant leaves the vehicle. You need no object Init call. Aircraft remain excluded by default. Test an explicit class profile before allowing any airframe.

## Choose the safety rules

All settings are existing rows in `MissionConfig/interfaceConfig.sqf`. The shipped defaults allow sustained overturn and destruction, preserve momentum, protect the player for two seconds, search six metres for a clear exit, and apply no extra damage. The overturn must last one second. `Waldo_EmergencyDismount_AllowedKinds` starts as `["LandVehicle", "Ship"]`.

For a strict exit, set `Waldo_EmergencyDismount_RequireClearExit` to `true`. Extraction then refuses to proceed when no safe point exists. `Waldo_EmergencyDismount_UseEject` is an advanced engine path and starts `false`. Class-specific `Waldo_EmergencyDismount_VehicleProfiles` can override the general rule after you test that vehicle. The throw uses `ThrowBaseVelocity = 4.5`, `ThrowAngularFactor = 1.25`, `ThrowMaximumVelocity = 14`, and `UpwardVelocity = 3`. These are metres per second except for the angular multiplier.

## Runtime and troubleshooting

`Waldo_fnc_EmergencyDismountInit` installs the local checks; `Waldo_fnc_EmergencyDismountStop` removes them. WMP starts the feature from its config and intentionally has no ZEN module. If no extraction occurs, check the enable flag, simulation, allowed vehicle kind, one-second rollover delay, and the clear-exit policy. A brief rock onto two wheels is not a sustained rollover.

## See also

- [Set Vehicle Upright](Vehicle-Uprighting)
- [Vehicle Recovery](Vehicle-Recovery)
- [Optional Feature Extensions](Optional-Feature-Extensions) for per-class profiles

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)

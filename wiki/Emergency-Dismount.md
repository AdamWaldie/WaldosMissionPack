# Emergency Dismount

> **Use this page when:** occupants should be extracted from an overturned or destroyed land vehicle or boat.

Emergency Dismount moves an occupant to nearby clear ground and gives them a short damage-protection window. A rollover also gives the occupant a bounded outward and upward velocity based on the flip. It is separate from the action that rights a tipped vehicle.

## Enable and try it

Open `MissionConfig/interfaceConfig.sqf` and change the existing `Waldo_EmergencyDismount_Enable` row from `false` to `true`. Start the mission with a simulation-enabled land vehicle. Roll it with a player inside, or destroy it, and check that the occupant leaves the vehicle. You need no object Init call. Aircraft remain excluded by default. Test an explicit class profile before allowing any airframe.

## Choose the safety rules

Edit the existing rows in `MissionConfig/interfaceConfig.sqf`. Every name below starts with `Waldo_EmergencyDismount_`.

| Setting suffix | Type | Shipped value | What it changes |
|---|---|---|---|
| `Enable` | Boolean | `false` | Installs local extraction actions. |
| `OnOverturn` | Boolean | `true` | Allows extraction after a sustained rollover. |
| `OnDestroyed` | Boolean | `true` | Allows extraction from a destroyed eligible vehicle. |
| `PreserveVelocity` | Boolean | `true` | Carries vehicle motion into the exit. Advanced: test the vehicle class. |
| `ProtectDuringExit` | Boolean | `true` | Temporarily prevents relocation damage. |
| `ProtectionSeconds` | Number | `2` | Duration of that protection. |
| `ClearPositionRadius` | Number | `6` | Metres searched for a safe exit point. |
| `RequireClearExit` | Boolean | `false` | Set `true` to refuse extraction when no clear point exists. |
| `UseEject` | Boolean | `false` | Advanced engine ejection path instead of WMP's safe relocation. |
| `RecoverUnconscious` | Boolean | `false` | Allows moving an unconscious occupant. |
| `MinimumOverturnSeconds` | Number | `1` | Continuous rollover time required before extraction. |
| `DamageOnExit` | Number | `0` | Additional damage fraction from `0` to `1`. |
| `ThrowBaseVelocity` | Number | `4.5` | Minimum horizontal throw speed in metres per second. |
| `ThrowAngularFactor` | Number | `1.25` | Multiplier for speed gained from the flip. |
| `ThrowMaximumVelocity` | Number | `14` | Cap for the horizontal throw contribution, in metres per second. |
| `UpwardVelocity` | Number | `3` | Minimum upward speed in metres per second. |
| `Cooldown` | Number | `8` | Seconds before another automatic extraction attempt. |
| `AllowedKinds` | Array of strings | `["LandVehicle", "Ship"]` | Accepted `isKindOf` roots. Aircraft are excluded. |
| `VehicleProfiles` | HashMap | Empty | Exact vehicle classname to per-class safety overrides. Test each override in Arma. |

## Runtime and troubleshooting

WMP starts the feature from its config and intentionally has no ZEN module. Its local `Waldo_fnc_EmergencyDismountInit` and `Waldo_fnc_EmergencyDismountStop` calls take no arguments. Init installs the check on each player, including JIP, and returns `true` when active or already running. It returns `false` when unavailable or disabled. Stop removes the local monitor and returns no useful value. Normal missions should change the config row rather than call these lifecycle functions directly. If no extraction occurs, check the enable flag, simulation, allowed vehicle kind, one-second rollover delay, and the clear-exit policy. A brief rock onto two wheels is not a sustained rollover.

## See also

- [Set Vehicle Upright](Vehicle-Uprighting)
- [Vehicle Recovery](Vehicle-Recovery)
- [Optional Feature Extensions](Optional-Feature-Extensions) for per-class profiles

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)

# Hazardous Environments

> **Use this page when:** an area or moving object should expose players to radiation or another configured hazard.

Hazards track exposure on each player, show a continuous status panel, and can apply damage after thresholds. The pack includes three radiation profiles, so a first mission does not need a custom damage model. The server owns zones. Clients, including late joiners, receive their current state.

## Create a first zone

1. In `MissionConfig/environmentConfig.sqf`, change the existing `Waldo_Hazard_Enable` row from `false` to `true`.
2. Place an Eden marker named `reactor_zone` over the affected area.
3. Add this call to `initServer.sqf`:

   ```sqf
   ["reactor_leak", "reactor_zone", "MODERATE_RADIATION"] call Waldo_fnc_HazardRegisterPresetZone;
   ```

4. Walk into the marked area. The lower-left panel reports exposure. `LOW_RADIATION` and `SEVERE_RADIATION` are the other shipped presets. Zeus can create or remove a zone through the Hazard modules instead of adding a permanent mission call.

`Waldo_fnc_HazardRegisterPresetZone` accepts:

| Position | Type | Default | What to supply |
|---|---|---|---|
| 0 | String | Required | Stable unique key, such as `"reactor_leak"`. Reusing it replaces that zone. |
| 1 | Object, marker-name string or area array | Required | A trigger or moving object, an existing marker name, `[position, radius]`, or `[position, axisA, axisB, angle, rectangle]`. Positions are `[x, y, z]` world arrays and distances are metres. |
| 2 | String | `"LOW_RADIATION"` | Key in `Waldo_Hazard_Presets`. The pack also ships `"MODERATE_RADIATION"` and `"SEVERE_RADIATION"`. |
| 3 | HashMap | Empty | Profile keys that override this one zone's copy of the preset. |

The server returns `true` after accepting or queueing a known preset, otherwise `false`. A call before shared config is ready queues itself. Run the call on the server or in an Eden object Init field, not in an unguarded per-client script.

For a profile without a preset, use `[_key, _area, _profile] call Waldo_fnc_HazardRegisterZone`. The first two arguments use the same types. The third is a HashMap of the profile keys below. The server returns `true` when it accepts the zone and publishes the revised registry to current players and JIP.

For a moving source, use `[_key, _object, _radius, _profile] call Waldo_fnc_HazardRegisterEmitter`. The arguments are a unique string, an existing object, a number of metres (default `3`) and a profile HashMap. It returns `true` after registration. WMP removes this zone when the emitter object is deleted.

## Change the player feedback

Edit existing rows in `MissionConfig/environmentConfig.sqf`. Each name in this table starts with `Waldo_Hazard_`.

| Setting suffix | Type | Shipped value | What it changes |
|---|---|---|---|
| `Enable` | Boolean | `false` | Starts exposure evaluation. Register a zone separately. |
| `Interval` | Number | `1` | Seconds between checks on each player. Reducing it increases client work. |
| `ShowStatus` | Boolean | `true` | Shows one live exposure panel. |
| `StatusGraceSeconds` | Number | `6` | Seconds the panel remains after leaving every zone of that type. |
| `NotifyTransitions` | Boolean | `true` | Shows entry and exit cards when the player can perceive the hazard. |
| `NotificationDuration` | Number | `6` | Seconds those cards remain. |
| `DosimeterEnable` | Boolean | `true` | Offers exposure-reading interactions. |
| `DosimeterRequireItem` | Boolean | `false` | Requires an accepted item before reading exposure. |
| `DosimeterItems` | Array of classnames | `[]` | Accepted carried or assigned items. Populate this before requiring one. |
| `Treatments` | Array of `[classname, label, reduction]` rows | Shipped treatment rows | ACE item to consume, player-facing name, and dose removed. Empty disables treatment. |
| `TreatmentDuration` | Number | `4` | Seconds the ACE treatment action must complete before consuming an item. |
| `TreatmentMedicOnly` | Boolean | `false` | Requires the administering unit's Medic trait. |
| `Presets` | HashMap | Three radiation profiles | Named templates that zone registration can copy and override. |

## Profile fields

The profile is a HashMap, not a list of positional values. A preset already fills these fields. Add only the keys that differ when you supply an override HashMap.

| Key | Type | Default without a preset | What it changes |
|---|---|---|---|
| `type` | String | `""` | Exposure category. Zones with the same type add to one dose. |
| `label` | String | `""` | Name in messages and optional marker. |
| `intensityMode` | String | `"LINEAR"` | `"LINEAR"` fades toward an area's edge; `"CONSTANT"` uses full intensity inside. |
| `rate` | Number | `1` | Exposure gained per second at full intensity. |
| `decay` | Number | `0.1` | Exposure lost per second outside the zone. |
| `decontaminationRate` | Number | `1` | Exposure lost per second while protected inside. |
| `maximumExposure` | Number | `1e10` | Upper dose limit. |
| `damageThresholds` | Array of `[exposure, damage per tick]` rows | `[]` | Ordered damage tiers. |
| `fatalExposure` | Number | Unset | Dose at which the player dies. `-1` disables this threshold. |
| `protectIndoors`, `protectInVehicles` | Boolean | Preset-dependent | Protection inside a building or vehicle. |
| `showStatus`, `notifyTransitions` | Boolean | Mission-wide choice | Override the panel or entry/exit cards for this profile. |
| `markerEnabled` | Boolean | `false` | Show an object-following or area-centred 3D warning marker. |
| `marker` | HashMap | WMP warning appearance | Optional marker icon, colour, text, offset, distance or sides. |
| `detectorItems`, `detectorObjects` | Arrays | Unset | Restrict awareness of status and notices, not exposure or protection. |

For example, `createHashMapFromArray [["rate", 0.5], ["markerEnabled", true]]` changes only the selected preset's rate and marker. Profiles can also set callback names for entry, exit or tick events. Store callback code in `missionNamespace` and pass its function-name string; raw code does not survive the JIP snapshot. See [Optional Feature Systems](Optional-Feature-Systems#hazardous-environments) for audio, shielding and callback details.

## Remove or diagnose a zone

Use the Hazard removal module or `["reactor_leak"] call Waldo_fnc_HazardUnregisterZone` on the server. The required argument is the registered key string. It returns `true` when it removes a zone and `false` when the key is unknown. WMP removes its 3D marker and republishes the registry. Exposure resets on player respawn and on ACE full heal. If no panel appears, check the enable flag, area name and whether the player is inside it. A profile that requires a detector can hide status from an unaware player without preventing exposure or damage.

## See also

- [Custom 3D World Markers](Custom-3D-World-Markers) for optional zone markers
- [Optional Feature Extensions](Optional-Feature-Extensions) for moving emitters and engine limits

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)

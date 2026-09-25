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

The call takes `[unique key, area, preset key]`. It registers one server-owned zone. Do not repeat it on every client. For a moving source, use `[_key, _object, _radius, _profile] call Waldo_fnc_HazardRegisterEmitter`, with a profile obtained from `Waldo_Hazard_Presets`.

## Change the player feedback

Edit existing rows in `MissionConfig/environmentConfig.sqf`. `Waldo_Hazard_ShowStatus` and `Waldo_Hazard_NotifyTransitions` start `true`. `Waldo_Hazard_Interval` defaults to one second. Reducing it increases client work. `Waldo_Hazard_DosimeterEnable` starts `true`, while `Waldo_Hazard_DosimeterRequireItem` starts `false`. Add accepted classnames to `Waldo_Hazard_DosimeterItems` before requiring an item. Treatment rows contain `[item classname, readable name, exposure reduction]`. ACE handles the progress action.

Profiles can change intensity, decay, shielding, dose thresholds, awareness, audio and world markers. Zones with the same `type` contribute to one combined dose. See [Optional Feature Systems](Optional-Feature-Systems#hazardous-environments) for the complete profile-key table and callback rules.

## Remove or diagnose a zone

Use the Hazard removal module or `Waldo_fnc_HazardUnregisterZone` on the server. Exposure resets on player respawn and on ACE full heal. If no panel appears, check the enable flag, area name and whether the player is inside it. A profile that requires a detector can hide status from an unaware player without preventing exposure or damage.

## See also

- [Custom 3D World Markers](Custom-3D-World-Markers) for optional zone markers
- [Optional Feature Extensions](Optional-Feature-Extensions) for moving emitters and engine limits

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)

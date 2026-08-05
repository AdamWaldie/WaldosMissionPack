# Hazardous environments

Repeatable contamination/toxic/temperature/vacuum-style exposure zones.
"Enable + register" pattern: enabling starts evaluation, but there is no
danger anywhere until a zone/emitter is registered.

## Config (`MissionConfig\environmentConfig.sqf` — shared)

```sqf
["Waldo_Hazard_Enable", false],             // master opt-in
["Waldo_Hazard_Interval", ...],             // local exposure update interval (seconds)
["Waldo_Hazard_ShowStatus", true],          // continuous lower-left exposure panel; never consumes notification lanes
["Waldo_Hazard_NotifyTransitions", true],   // entry/exit WMP cards
["Waldo_Hazard_NotificationDuration", 6],   // transition-card seconds
["Waldo_Hazard_DosimeterEnable", ...],      // enables exposure-reading ACE interactions
["Waldo_Hazard_DosimeterRequireItem", ...], // require a configured carried dosimeter item
["Waldo_Hazard_DosimeterItems", []],
["Waldo_Hazard_Treatments", [ /* [consumed item class, readable name, exposure reduction] rows */ ]],
["Waldo_Hazard_TreatmentDuration", ...],
["Waldo_Hazard_TreatmentMedicOnly", ...],
["Waldo_Hazard_Presets", createHashMapFromArray [ /* named profiles, see below */ ]]
```

## Shipped presets

`LOW_RADIATION`, `MODERATE_RADIATION`, `SEVERE_RADIATION` — ready-to-use
ionising-radiation examples with packaged Geiger/cough audio, increasing
dose rate/recovery/shielding/injury thresholds/fatal dose by severity. All
three deliberately share the `RADIATION` type so dose carries consistently
between radiation zones. A custom non-radiological profile should use its
own type ID (e.g. `TOXIN`, `NO_OXYGEN`) to keep exposure separate.

## Registering a zone (`initServer.sqf`)

```sqf
private _profile = (missionNamespace getVariable ["Waldo_Hazard_Presets", createHashMap])
    getOrDefault ["MODERATE_RADIATION", createHashMap];
["reactor_leak", "reactor_zone", _profile] call Waldo_fnc_HazardRegisterZone;   // zone: trigger/marker/[pos,radius]/[pos,axisA,axisB,angle,rect]
["leaking_truck", leakingTruck, 8, _profile] call Waldo_fnc_HazardRegisterEmitter; // moving-object emitter
```

`Waldo_fnc_HazardUnregisterZone` removes a zone server-side;
`Waldo_fnc_HazardStop` stops only the current client's local evaluation.

## Awareness / detector gating (information only, never protection)

Optional `detectorItems` (carried/worn item), `detectorObjects` +
`detectorObjectRange` (nearby object), or advanced `awarenessCondition`
(missionNamespace function-name string, JIP-safe) restrict who can *see*
hazard status/notices. An unaware player still accumulates exposure and
takes damage — these settings never grant protection. When any
detector/condition is configured it gates both the status panel and
transition/damage notices by default; override with
`requireAwarenessForStatus` / `requireAwarenessForNotifications` set `false`.

## Zeus

**Hazard - Create** (circular zone, preset + custom name/wording, linear or
constant intensity, range/exposure/recovery/cap/damage/fatal
threshold/vehicle protection/entry-exit notifications — a zero damage and
zero fatal threshold produces a non-injuring roleplay zone). **Hazard -
Remove Nearest**.

## Gotchas

- `damageThresholds` are ordered `[exposure, damage-per-tick]` tiers;
  `fatalExposure = -1` disables forced death at a threshold.
- For dedicated-safe callbacks, store the function in `missionNamespace` and
  reference it by name string — raw CODE is not transmitted as JIP state.
- Arbitrary 3D mesh volumes aren't reliable in SQF; compose supported shapes
  (circle/rotated rectangle-ellipse/marker/trigger) or use an editor trigger.

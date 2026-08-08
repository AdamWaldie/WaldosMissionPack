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

The beginner-friendly path — one call, preset name as a plain string, no
manual HashMap lookup:

```sqf
["reactor_leak", "reactor_zone", "MODERATE_RADIATION"] call Waldo_fnc_HazardRegisterPresetZone;
// [key, area, presetKey, overrides(optional)] - copies the preset so repeated calls never mutate the shared catalogue
```

The manual/advanced path, for a hand-built profile or when overriding
several fields at once:

```sqf
private _profile = (missionNamespace getVariable ["Waldo_Hazard_Presets", createHashMap])
    getOrDefault ["MODERATE_RADIATION", createHashMap];
["reactor_leak", "reactor_zone", _profile] call Waldo_fnc_HazardRegisterZone;   // zone: trigger/marker/[pos,radius]/[pos,axisA,axisB,angle,rect]
["leaking_truck", leakingTruck, 8, _profile] call Waldo_fnc_HazardRegisterEmitter; // moving-object emitter
```

`Waldo_fnc_HazardUnregisterZone` removes a zone server-side;
`Waldo_fnc_HazardStop` stops only the current client's local evaluation.
Called from an object's own Eden init field (as the shipped compositions
below do), `Waldo_fnc_HazardRegisterPresetZone` self-defers if `init.sqf`
hasn't finished loading `Waldo_Hazard_Presets` yet, so ordering against
`init.sqf` is never a beginner trap.

### Eden compositions (beginner drop-in)

Three shipped examples, each with a Minimal (smallest working call) and
Full (every option shown) pair:

- `[WMP]Hazardous_Emitter_Example_Minimal`/`_Full` — a fixed severe-radiation
  zone (`Waldo_fnc_HazardRegisterPresetZone`); Full adds an
  `intensityMode: CONSTANT` override.
- `[WMP]Hazard_Emitter_Moving_Example_Minimal`/`_Full` — a contamination
  field that follows a vehicle (`Waldo_fnc_HazardRegisterEmitter` directly,
  not the preset wrapper, since an emitter always needs an explicit
  profile).
- `[WMP]Radiation_Hazard_Example_Minimal`/`_Full` — "Radiation Hazard With
  Audio"; Minimal uses no overrides, Full adds
  `label`/`notifyTransitions`/`notifyDamageStages`/`showStatus` overrides
  on top of the `MODERATE_RADIATION` preset.

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

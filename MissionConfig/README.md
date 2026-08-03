# WMP feature configuration

Every file in this directory is mission-maker configuration. The feature files return pure data;
they do not start systems, wait for state, register handlers, mutate world objects, or transfer
authority.

## Customisation levels

Every setting is documented with one of these labels inside its config file and in the wiki:

- **MISSION MAKER** — intended to be reviewed for each mission. These select enabled features,
  factions/classes, player-facing behaviour, scenario rules, names and content pools.
- **ADVANCED TUNING** — a supported setting, but the shipped value should normally remain unchanged.
  Change it only for a specific design requirement and test the affected feature in hosted and
  dedicated multiplayer. Timers, safety bounds, scan intervals, UI layout internals and control-loop
  values usually belong here.
- **COMPATIBILITY** — retained for integration or an older call path. Do not edit it as ordinary
  mission configuration unless its comment explicitly tells you to do so.

Units, valid string options, array/HashMap shapes and special values such as `-1` are stated beside
the setting. A Boolean is not self-explanatory: its comment describes what `true` actually changes.
Do not change a setting merely because it is exposed.

## Files

- `acreConfig.sqf` — ACRE2 nets, presets, same-type radio occurrences/ears, group/player/role allocation and Babel. It never controls alternate PTT defaults.
- `aiConfig.sqf` — AI rebalance and improved AI helicopter landings.
- `airOperationsConfig.sqf` — airborne gunship, paradrop and Dynamic AA.
- `electronicWarfareConfig.sqf` — jammer/EW behavior and RDF feedback.
- `environmentConfig.sqf` — hazardous environments, tree felling and breaching.
- `interfaceConfig.sqf` — themes, notification flow, treatment feedback, tactical display,
  emergency dismount and accessibility.
- `logisticsConfig.sqf` — field resupply, vehicle recovery, object scaling and logistics crates.
- `missionSystemsConfig.sqf` — rally points, economy enablement, minigames, corpse traps, ACE
  logistics limits, diagnostics and safestart.
- `persistenceConfig.sqf` — INIDBI2 persistence fields.
- `featureConfigManifest.sqf` — deterministic list consumed by the loader.

## Feature-config schema

Each feature file returns a HashMap. Supported keys are:

- `featureFamilies`: display/documentation names only.
- `shared`: `[variableName, defaultValue]` entries applied from `init.sqf` on every machine.
- `server`: `[variableName, defaultValue, publishForJip]` entries applied only from
  `initServer.sqf`. A true publication flag broadcasts the retained/default value.
- `playerLocal`: `[variableName, defaultValue]` entries applied only inside the `hasInterface`
  branch of `initPlayerLocal.sqf`.
- `aliases`: `[scope, targetName, sourceName]` entries that copy a configured source only when the
  target is undefined.
- `fallbacks`: `[scope, targetName, sourceName, defaultValue]` entries that retain a compatible
  source variable when present, otherwise use the supplied default.
- `conditional`: `[scope, variableName, requiredCfgPatch, loadedDefault, absentDefault,
  publishForJip]` entries for dependency-sensitive defaults.

All ordinary entries are guarded: a value supplied before the loader runs wins. Server/ZEN runtime
changes continue to win for connected and JIP clients because shared/player-local loading never
publishes, and only `initServer.sqf` processes server publication entries.

`Waldo_fnc_LoadFeatureConfigs` is lifecycle code and therefore lives under
`MissionScripts\MissionInit\Configuration`, not in this directory. See the wiki
**Feature Configuration Files** page for every setting, units, valid values, and ownership.

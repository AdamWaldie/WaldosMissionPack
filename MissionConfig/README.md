# WMP feature configuration

Feature defaults are separated by execution locality so editing configuration cannot silently move
authority or activation:

- `SharedFeatureDefaults.sqf` runs synchronously on every machine from `init.sqf`. It contains only
  guarded values used across localities.
- `ServerFeatureDefaults.sqf` runs only from `initServer.sqf`. It owns authoritative defaults and
  their JIP-safe publication.
- `PlayerLocalFeatureDefaults.sqf` runs only inside the `hasInterface` branch of
  `initPlayerLocal.sqf`. It contains presentation and local-interaction defaults.
- `acreConfig.sqf` remains at mission root because ACRE must load it during CfgFunctions pre-init,
  before the three event-script entry points.

Do not start systems, wait for state, or add event handlers in these files. Those lifecycle actions
remain in the corresponding init entry point. All defaults are repeat-safe, and server-authored
state must continue to use guarded reads plus explicit publication for JIP.

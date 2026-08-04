# AI rebalance (AITweak)

Config lives in `init.sqf`:

```sqf
Waldo_AIRebalance_Enable = true;
Waldo_AIRebalance_Profile = "LEGACY"; // LEGACY | PUBLIC | STANDARD | VETERAN
["DAY", Waldo_AIRebalance_Profile] call Waldo_fnc_AITweak;
```

- First arg is `"DAY"` or `"NIGHT"` — NIGHT reduces unaided (no-NVG) spotting
  more strongly than NVG-assisted spotting, so call it again at
  dusk/dawn transitions if the mission has a day/night cycle worth tuning for.
- `LEGACY` preserves the pack's original, established balance — pick this if
  the mission has been running with WMP before and shouldn't feel different.
- `PUBLIC`, `STANDARD`, `VETERAN` are lower-lethality/balanced alternatives
  for new missions; missions can layer faction- and role-specific hash-map
  overrides on top of whichever profile is chosen (ask if the user wants
  this level of granularity — it's an advanced option, not needed by default).
- All-machine initialiser by design: AI ownership and detonation-event
  locality can move across server, client, and headless-client machines, so
  don't restructure this to run server-only.
- Runtime changes are also available via **Waldos Mission Modules** in Zeus,
  which routes through `Waldo_fnc_FeatureRuntimeApply` — same effect as
  editing `init.sqf`, useful for adjusting mid-mission without a restart.

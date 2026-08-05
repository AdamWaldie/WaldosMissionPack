# TFAR (Task Force Arrowhead Radio) — optional

**What WMP wraps:** effectively nothing scripted — see `CLAUDE.md`'s TFAR
section. WMP reads the `radio` inventory slot from `mission.sqm` for
loadout scraping (`loadout-logistics.md`) and drives TFAR's client-side
distance-multiplier variables during jamming (`jamming.md`); everything
else about TFAR is native Eden Editor configuration, not WMP scripting.
Check those two files first for anything WMP touches.

## What TFAR provides, in general

TFAR is the long-standing alternative to ACRE2 for realistic radio
simulation, with a key structural difference relevant to mission makers:

- **Native Eden Editor integration** — TFAR radios are assigned to units
  through the 3Den unit properties panel directly, not through a
  scripting API a mission maker has to call. This is why WMP has no
  equivalent to `acreConfig.sqf` for TFAR — there is nothing to configure
  in script terms; it's entirely an Eden placement/property concern.
- **Similar radio-simulation concepts to ACRE2** at a high level — distance
  and terrain-affected signal quality, direct/proximity voice alongside
  radio voice, multiple radio hardware classes — but its own distinct
  implementation and settings, not a drop-in equivalent API.
- **No native jamming/custom-signal hook** exposed to missions the way
  ACRE2's `acre_api_fnc_setCustomSignalFunc` is — this is why WMP's jamming
  feature drives TFAR indirectly via its exposed client-side unit
  variables (`tf_receivingDistanceMultiplicator`,
  `tf_sendingDistanceMultiplicator`, `tf_unable_to_use_radio`, per
  `jamming.md`) rather than a proper signal-model hook, and why TFAR
  jamming is always broadband (no per-frequency-band filtering, unlike
  ACRE2 jamming's optional `bands` parameter).
- **Its own in-game settings and addon-options surface** — volume, spatial
  audio, keybinds — configured the same general way as ACRE2's, via the
  mod's own interface, not through WMP.
- Like ACRE2, typically requires a **separate client-side companion
  component** beyond the Arma mod itself for the voice engine to function
  — don't assert the exact current architecture without checking the
  mod's own current setup docs.

## Official documentation

| | |
|---|---|
| GitHub | search GitHub for "Task Force Arrowhead Radio" / TFAR if the exact org/repo isn't already known with confidence — don't guess at the spelling |
| Wiki/docs | the repository's wiki is the norm for TFAR's settings and per-radio configuration outside what WMP touches |
| Steam Workshop | search Steam Workshop for "Task Force Arrowhead Radio" |
| Support | the project's GitHub Issues, or its Discord if linked from the repo/Workshop page |

## Common troubleshooting specific to TFAR

- Radios not appearing in supply crates: confirm the unit actually has a
  radio assigned via the Eden Editor unit properties panel — WMP only
  scrapes whatever is already in the `radio` inventory slot, it cannot
  assign one.
- Jamming appearing to have no effect on a TFAR radio: confirm
  `task_force_radio`/`tfar_core` is actually present in `CfgPatches` (see
  `mod-detection.md`) — the jamming engine gates on this exactly the same
  way it gates on ACRE2's presence.

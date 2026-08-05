# ACRE2 (Advanced Combat Radio Environment 2) — optional, as a mod

This file is about **ACRE2 itself** as a radio-simulation mod. For WMP's
own integration — automated per-mission radio assignment from
`MissionConfig\acreConfig.sqf`, the jamming custom-signal hook, Babel — see
`references/acre2.md` and `references/jamming.md` first. Check those before
this file for anything WMP configures.

## What ACRE2 provides, in general

ACRE2 replaces vanilla/side-chat-style voice with a simulated radio-and-
proximity communications model:

- **Realistic radio propagation** — signal quality is affected by
  distance, terrain line-of-sight, and radio power, rather than a flat
  always-on channel. WMP's jamming feature (`jamming.md`) hooks directly
  into this via ACRE2's custom-signal-function API.
- **Multiple signal models**, selectable per mission: *LOS Simple*
  (line-of-sight only, no custom hook support), *LOS Multipath* (the
  default, adds multipath/terrain modelling and is required for WMP's
  jamming custom signal hook to be called at all), and *Arcade* (a
  simplified always-connected mode, also compatible with WMP's jamming
  hook). See `acre2.md`/`jamming.md` for why this specific setting matters
  to WMP.
- **Simulated radio hardware** — a roster of modelled radio classes
  (handheld and vehicle-mounted, short- and long-range, different
  bands/channel counts) rather than one universal channel — see
  `acre2.md`'s "radio families" for the exact set WMP's config model
  understands (`PRC_LR`, `BF888`, `SEM52`, `LEGACY_VHF`).
- **In-game proximity/direct voice** alongside radio voice — nearby players
  can hear each other directly (with distance-based volume/muffling) even
  without a shared radio channel, distinct from transmitted radio audio.
- **Babel** — an optional in-simulation language-barrier system (only
  players who understand a spoken language hear it clearly; others hear
  garbled/foreign speech) — WMP's own Babel wiring lives in `acre2.md`.
- **A client-side companion component** beyond the Arma mod/addon itself —
  ACRE2 typically requires a separate client-side installer/plugin in
  addition to the Arma workshop mod for its voice engine to function.
  Don't assert the exact current architecture (which voice backend it
  integrates with) without checking the mod's own setup docs — this has
  changed across ACRE2's history and stating it wrong actively breaks a
  user's install troubleshooting.
- **Its own in-game settings interface** — radio volume, spatial audio
  behaviour, push-to-talk keybind configuration — separate from anything
  `acreConfig.sqf` controls, which only sets the *starting* channel/net
  plan, not personal audio preferences.

## Official documentation

| | |
|---|---|
| GitHub | search GitHub for the ACRE2 repository (commonly associated with IDI Systems) if the exact org/repo spelling isn't already known with confidence — don't guess |
| Wiki/docs | the repository's own wiki is the norm for these mods — check there for the full `acre_api_fnc_*` scripting surface (custom signal functions beyond WMP's jamming hook, Babel API, preset management) and for current client-side setup instructions |
| Steam Workshop | search Steam Workshop for "ACRE2" |
| Support | the project's GitHub Issues, or its Discord if one is linked from the repo/Workshop page — don't rely on a memorized invite link |

## Common troubleshooting specific to ACRE2

- "Jamming doesn't do anything" with ACRE2 installed → check the mission's
  selected signal model first (`acre2.md`/`jamming.md`) — this is the
  single most common ACRE2+WMP interaction issue and is entirely a mission
  setting, not a bug.
- Channel *naming* not displaying on-radio (only in the CEOI) is a known
  ACRE2 API limitation WMP works around deliberately — see `acre2.md`, not
  a bug to "fix."
- A player reporting no radio audio at all is very often the separate
  client-side companion component not installed/configured, not a WMP or
  mission configuration problem — rule that out before troubleshooting
  `acreConfig.sqf`.

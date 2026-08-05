# CBA_A3 (Community Base Addons) — required

**What WMP wraps:** see `CLAUDE.md`'s "CBA_A3" section and
`arma-scripting-architecture.md`'s "event-handler ecosystem" section for
exactly which CBA functions WMP itself calls
(`CBA_fnc_addEventHandler`/`addClassEventHandler` for the pack's respawn
and AI-skill handlers, `CBA_fnc_execNextFrame`, `CBA_fnc_hashCreate`/
`hashGet`, `CBA_fnc_setPos`/`setHeight`, `CBA_fnc_notify`). Check that
first — this file is about CBA as a general-purpose framework beyond those
specific calls.

## What CBA provides, in general

CBA is the de facto standard base-addon layer almost every modern Arma 3
mod (including WMP itself) builds on. Its core systems, at the depth a
mission maker actually needs to recognise them:

- **Extended Event Handlers (XEH)** — a broader, more consistent set of
  object-lifecycle events than vanilla's native event handler list alone
  provides, plus the class-scoped `CBA_fnc_addClassEventHandler` pattern
  documented in `arma-scripting-architecture.md`. This is the mechanism
  most other CBA-dependent mods (and WMP) use instead of manually attaching
  a vanilla `addEventHandler` to every individual unit.
- **A global named-event system** — `CBA_fnc_addEventHandler` (listen),
  `CBA_fnc_localEvent` (fire on the current machine),
  and a global-broadcast counterpart for firing an event across the
  network — lets any script raise/listen for a named event without either
  side needing a direct reference to the other's object or thread. This is
  the backbone WMP's own optional-feature runtime settings and several
  Zeus-triggered actions are built on.
- **The CBA Settings framework** — lets an addon expose user-adjustable
  settings that surface in the in-game **Addon Options** menu (accessible
  from the main menu or in-mission via the pause menu, depending on
  context) without the addon author building its own settings UI. Several
  mods WMP depends on (ACE3 modules, LAMBS sub-mods) use this for their own
  per-feature toggles — see each mod's own file in this directory.
- **A keybinding API** (`CBA_fnc_addKeybind`) — lets an addon register a
  custom keybind that then appears in Arma's own **Configure > Controls**
  menu for the player to bind, rather than hard-coding a key.
- **A general-purpose function/math/string/array helper library** —
  `CBA_fnc_*` utility functions covering common needs (array/string
  helpers, vector/heading math, misc conveniences) that most CBA-dependent
  mods lean on instead of reimplementing the same helpers themselves.
- **Compatibility/bugfix layer** — CBA also ships a number of vanilla-Arma
  bugfixes and behaviour normalisations that other mods (and missions)
  implicitly rely on once CBA is loaded.

## Official documentation

| | |
|---|---|
| GitHub | `https://github.com/CBATeam/CBA_A3` |
| Wiki/docs | `https://github.com/CBATeam/CBA_A3/wiki` — the standard source for the full function library, the Settings framework, the Extended Event Handler list, and the keybinding API in detail |
| Support | GitHub Issues on the repo above for bugs; the wiki's function-category pages are the right first stop for "does CBA already have a function for X" before writing a custom helper |

## Notes for extending WMP

Any mission-maker script that fires or listens for a WMP-relevant global
event, or wants a settings/keybind UI consistent with how WMP and its
dependencies present theirs, is a candidate for CBA's own event/settings/
keybind systems above rather than a hand-rolled equivalent — check the CBA
wiki's relevant section before building a parallel mechanism.

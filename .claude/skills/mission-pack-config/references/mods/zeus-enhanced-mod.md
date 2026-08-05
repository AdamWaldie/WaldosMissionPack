# Zeus Enhanced (ZEN) — optional, as a mod

**What WMP wraps:** WMP's own "Waldos Mission Modules" and the newer
domain-specific categories (WMP Combat Systems, WMP Logistics, WMP
Transport, Waldos Economy Systems, etc.) are custom modules WMP registers
*through* ZEN's own registration API — see `references/zeus-modules.md`
for the full index of what WMP itself registers, and `CLAUDE.md`'s "Zeus
Enhanced" section for the two specific functions WMP calls
(`zen_custom_modules_fnc_register`, `zen_dialog_fnc_create`). Check those
first — this file is about ZEN's own built-in functionality and the
general module-authoring framework beyond WMP's specific usage of it.

## What Zeus Enhanced provides, in general

ZEN is a curator-experience overhaul mod, not just a framework other mods
plug into — it ships its own substantial functionality on top of vanilla
Zeus:

- **A custom-module registration framework** —
  `zen_custom_modules_fnc_register` lets any addon/mission add its own
  entries to the Zeus module palette under a named category, and
  `zen_dialog_fnc_create` provides a parameter-input dialog for that
  module's options — this is the exact mechanism WMP's own Zeus modules
  are built on. Writing a *new* custom module from scratch (beyond
  extending WMP's own) means learning this pair of functions and the
  dialog-field schema they accept — check ZEN's own docs for the full
  dialog field-type list (text input, dropdown, checkbox, slider, etc.)
  and the exact registration call signature, since the two functions
  cited in `CLAUDE.md` show WMP's own usage pattern, not the complete API
  surface.
- **Built-in quality-of-life curator tools** beyond the custom-module
  framework — camera/movement improvements, group and unit management
  conveniences, and other stock ZEN modules that ship with the mod
  independent of any mission's own custom modules. The exact current set
  of stock modules changes between ZEN releases — check the mod's own docs
  for what's currently included rather than assuming a fixed list.
- **Its own settings** (via CBA Settings, see `cba.md`) governing curator
  UI behaviour, independent of anything WMP configures.

## Configuration surface outside WMP

ZEN's own stock modules and general curator-experience settings are
configured through the mod's own settings/Addon Options, not through
`MissionConfig` or any WMP call — WMP only adds *additional* modules
alongside ZEN's stock ones, it doesn't modify or configure ZEN's own
built-in functionality.

## Official documentation

| | |
|---|---|
| GitHub | search GitHub for "Zeus Enhanced Arma 3" if the exact repo isn't already known with confidence — don't guess at the org/repo spelling |
| Wiki/docs | the repository's wiki is the norm for documenting the full custom-module registration API (dialog field types, module categories, icon requirements) and ZEN's own built-in module list |
| Steam Workshop | search Steam Workshop for "Zeus Enhanced" |
| Support | the project's GitHub Issues, or its Discord if linked from the repo/Workshop page |

## Common troubleshooting specific to ZEN

- WMP's entire Zeus-facing surface silently disappears without ZEN loaded
  — this is expected (`mod-detection.md`), not a ZEN or WMP bug; every WMP
  Zeus registration script guards on `zen_main` in `CfgPatches` and simply
  exits if absent.
- A custom module a mission maker is building from scratch that doesn't
  appear in the Zeus palette is very often a registration-category or
  icon-path issue in `zen_custom_modules_fnc_register`'s own arguments,
  not a WMP-adjacent problem — check ZEN's own framework docs for the
  exact expected call shape rather than assuming from WMP's usage alone,
  since WMP's own registration script (`Waldo_fnc_ZenInitModules`) is one
  example usage, not the API reference.

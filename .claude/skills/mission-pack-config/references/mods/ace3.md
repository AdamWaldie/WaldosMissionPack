# ACE3 (Advanced Combat Environment) — required

**What WMP wraps:** see `CLAUDE.md`'s "ACE3" section for WMP's own call
patterns (interaction-menu actions, progress bars, limited arsenals, cargo/
dragging setup, fortify budget, weapon safety locking) — ACE3 is WMP's
single most heavily used dependency (~80 call sites), so a lot of "how does
ACE work" questions are actually answered by a specific WMP feature file
already: `loadout-logistics.md` (arsenal/cargo), `mhq.md` (deploy/teardown
actions), `references/misc-mission-maker-tools.md`'s Automatic ACE Fortify
Setup section, `endex-aar.md` (safety-mode locking + full heal),
`medical-feedback.md` (ACE medical event feedback). Check those first —
this file is about ACE3's own systems beyond what WMP configures.

## What ACE3 provides, in general

ACE3 is a large, modular overhaul mod — each module below is independently
toggleable server-side and has its own settings surface (mostly via the
CBA Settings framework, see `cba.md`):

- **Medical** — replaces vanilla health with a wound/bleeding/pain/
  consciousness simulation. Ships two tiers: **Basic** (simplified,
  closer to vanilla pacing) and **Advanced** (full body-part damage,
  bleeding rates, medications, surgical kits, IVs) — the mission/server
  chooses which tier via ACE's own settings, independent of anything WMP
  configures. WMP's `medical-feedback.md` only adds notification
  presentation on top of whichever tier the mission runs.
- **Arsenal** — a virtual loadout-editing interface (`ace_arsenal_fnc_*`)
  that can be opened on any box/vehicle, with per-container item
  restriction. WMP uses this to build limited crate arsenals from scraped
  mission.sqm loadouts (`loadout-logistics.md`) — the full arsenal API
  (custom stat-display panels, virtual-item camo groups, load-carrying
  weight display) goes well beyond what WMP touches.
- **Interaction menu** — the scroll-wheel "self interact"/"target
  interact" radial menu almost every ACE-dependent feature (WMP's own
  included) hangs its actions off, via
  `ace_interact_menu_fnc_createAction`/`addActionToObject`.
- **Cargo / dragging / carrying** — object-portability framework
  (`ace_cargo_fnc_setSpace`/`setSize`, `ace_dragging_fnc_setDraggable`/
  `setCarryable`) WMP uses for supply crates and recovery packages.
- **Fortify** — a curated per-side build-budget/catalogue system for
  in-mission base construction, which WMP's Automatic ACE Fortify Setup
  wraps to populate from synced Eden objects rather than a hand-authored
  catalogue.
- **Captives** — handcuffing, prisoner transport, surrender mechanics.
- **Explosives** — placing, wiring, remote/timed detonation, and defusal
  of demolition charges — the mechanism WMP's `breaching.md` requires
  (an ACE demo charge/satchel detonation is what triggers a configured
  breach profile).
- **Logistics (repair/rearm/refuel)** — vehicle field-servicing actions,
  separate from WMP's own vehicle-recovery system (`vehicle-recovery-rallies.md`)
  though the two can coexist on the same vehicle.
- **Hearing** — temporary deafness/tinnitus simulation from nearby
  explosions/gunfire, with its own volume-recovery settings — related to
  but distinct from the `ace_hearing_disableVolumeUpdate` global policy
  value WMP exposes in `MissionConfig\missionSystemsConfig.sqf` (see
  `misc-mission-maker-tools.md`/the relevant logistics file), which only
  controls whether ACE's automatic hearing-volume adjustment runs at all.
- Other modules present in a typical ACE3 install: **Weather** (wind/
  weapon-drift effects), **Advanced Ballistics**, **Fatigue** (stamina
  overhaul), **Night vision** presentation changes, **Overheating**
  (weapon jamming from sustained fire), **Maptools**, and Zeus-specific
  ACE additions — check ACE's own docs for the current full module list
  rather than assuming this enumeration is exhaustive; ACE3 adds/reworks
  modules between releases.

## Configuration surface outside WMP

Most ACE3 module settings (medical tier, whether a given module is enabled
at all, damage multipliers, interaction-menu keybind, hearing behaviour,
etc.) are configured through the **CBA Settings / Addon Options** framework
(see `cba.md`) — a server-side `.hpp`/profile-based override, or in-mission
via the settings menu depending on how the server locks them. This is
entirely separate from anything in `MissionConfig\*.sqf` — WMP does not
wrap ACE's own module-enable settings, only specific call sites listed
above.

## Official documentation

| | |
|---|---|
| GitHub | `https://github.com/acemod/ACE3` |
| Wiki/docs | `https://github.com/acemod/ACE3/wiki` and the dedicated docs site `https://ace3mod.com/` — both cover the full module list, each module's settings, and framework guides for extending ACE (e.g. adding a custom medical injury type, a custom arsenal item, a new interaction menu entry) |
| Support | GitHub Issues on the repo for bugs/feature requests; the wiki's "Framework" pages are the right starting point for "how do I build my own ACE-style feature" from scratch |

## Common troubleshooting specific to ACE3

- A feature that silently does nothing is very often just the wrong
  medical tier or a disabled module for that specific server config — check
  ACE's own settings before assuming a script bug.
- WMP-specific ACE interaction: several WMP features register **both** an
  ACE action and a vanilla `addAction` fallback for when ACE isn't loaded
  or its interaction system is unavailable (the "dual-surface policy"
  described in `CLAUDE.md`'s Waldos Economy Systems section, applied more
  broadly across the pack) — if an ACE action doesn't appear, check whether
  the vanilla fallback did instead, which usually confirms it's an ACE
  availability issue rather than a WMP bug.

# LAMBS series — optional, not directly integrated by WMP

**What WMP wraps:** nothing directly. `CLAUDE.md` lists LAMBS as
"complements AI behaviour generally" alongside WMP's own AI rebalance
(`ai-rebalance.md`) with **no WMP call sites into it** — the two systems
run independently and don't configure each other. If a mission runs both,
WMP's skill-profile application and LAMBS' behaviour tuning simply operate
on the same AI units side by side; there's nothing to reconcile in WMP's
own config.

## What LAMBS provides, in general

LAMBS is a family of **separate, independently-released** AI-behaviour
mods rather than one single addon — don't assume a mission that has "LAMBS"
installed has every sub-mod; each is typically distributed and updated on
its own:

- **LAMBS Danger.fsm** — replaces/reworks Arma's core AI reaction-to-danger
  finite state machine (see `arma-scripting-architecture.md`'s FSM note —
  this is exactly the kind of `.fsm`-based behaviour that note refers to,
  as distinct from an SQF script). Generally understood to improve how AI
  reacts to being shot at/spotting a threat (taking cover, returning fire,
  communicating contact) compared to vanilla behaviour.
- **LAMBS RPG** — AI use of anti-armor/rocket weapons, generally improving
  AI's willingness and competence to engage vehicles with the launchers
  they're carrying.
- **LAMBS Suppression** — AI reaction to suppressive fire (seeking cover,
  reduced accuracy/aggression while suppressed).
- **LAMBS Turrets** — AI gunner behaviour improvements for static and
  vehicle-mounted turrets.
- Each typically exposes its own tuning via the **CBA Settings framework**
  (see `cba.md`) — aggression/reaction-time/behaviour-strength type
  sliders — independent per sub-mod, not a single unified LAMBS settings
  panel.

Don't state more specific internal mechanics (exact FSM state names,
precise probability/timing tuning) without checking the relevant sub-mod's
own documentation — this is exactly the kind of native-mod-behaviour detail
this file intentionally doesn't assert with confidence.

## Official documentation

| | |
|---|---|
| GitHub | search GitHub for the specific LAMBS sub-mod by name (e.g. "LAMBS Danger.fsm", "LAMBS RPG", "LAMBS Suppression", "LAMBS Turrets") — don't assume a single unified repo covers all of them, and don't guess at author/org names |
| Wiki/docs | LAMBS documentation tends to live closer to each sub-mod's own repository readme than a separate wiki — check both the readme and any linked wiki page |
| Steam Workshop | search Steam Workshop for "LAMBS" plus the specific sub-mod name |
| Support | the relevant sub-mod's own GitHub Issues |

## Common troubleshooting specific to LAMBS

- AI behaviour looking "different than expected" when both WMP's AI
  rebalance and a LAMBS sub-mod are active is not necessarily a conflict —
  WMP tunes skill/spotting *values*, LAMBS tunes reaction *behaviour*
  (what the AI does once it has a given skill level), so both can be
  active and simply compounding, working as intended rather than fighting
  each other. If genuinely unexpected behaviour shows up, isolate by
  temporarily disabling one side (WMP's `Waldo_AIRebalance_Enable`, or the
  LAMBS sub-mod) rather than assuming either is broken.
- Performance concerns with LAMBS active are a LAMBS-side (FSM scheduler)
  question, not something WMP's own performance-audit tooling covers — see
  `arma-scripting-architecture.md`'s FSM note and `sqf-debugging.md`'s
  `diag_activeMissionFSMs` entry for a starting point if profiling is
  needed, but the mod's own docs/support channel for anything beyond that.

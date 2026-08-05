# SQF / Arma 3 engine basics (debugging support, not a scripting course)

Scope: vanilla Arma 3/SQF mechanics that come up while using WMP —
mainly for **debugging** ("what does this error mean", "why did nothing
happen"). This is not a scripting course. Any WMP-specific variable,
function, error message, or config field still routes to that feature's own
`references/*.md` file first — only fall back here for the underlying
engine/language mechanics those files assume the reader already knows.

## Core syntax recap

- Every statement ends `;`. A missing one is the single most common syntax
  error (see "Missing ;" below).
- `_local` (underscore prefix) is scoped to the current script/block;
  without the underscore, a variable is **global** and lives in
  `missionNamespace` unless explicitly assigned to another namespace
  (`profileNamespace`, `uiNamespace`, etc.).
- `missionNamespace setVariable ["Name", value, true];` — the trailing
  `true` broadcasts the change to every client (JIP included). Omit it (or
  use `false`) for a server/local-only value.
- Comments: `// line` or `/* block */`. `#include "path"` pastes another
  file's text at *compile* time, before the script runs — this matters for
  RPT line numbers, see below.
- Strings: `"double"` or `'single'` quotes, either works, stay consistent
  within a file. Nest one type inside the other rather than escaping.
- `params ["_a", ["_b", default]];` unpacks `_this` at the top of a
  function — the safe, self-documenting way to read call arguments instead
  of positional `_this select 0`.

## `call` vs `spawn` vs `execVM` vs `remoteExec`

| | Runs | Blocks caller? | Can `sleep`/`waitUntil`? | Returns a value? |
|---|---|---|---|---|
| `call` | Same thread, **unscheduled** environment | Yes | **No** — will hang/error | Yes |
| `spawn` | New thread, **scheduled** environment | No | Yes | No (returns a script handle) |
| `execVM "file.sqf"` | Compiles + `spawn`s a file | No | Yes | No (returns a script handle) |
| `remoteExec ["fnc", targets]` | Runs on other machine(s) | No (local side) | Depends on target's own thread | No (unless paired with JIP/callback pattern) |

- `call` runs **synchronously in the unscheduled environment** — if the
  called code contains `sleep` or a blocking `waitUntil`, it will either
  throw an error or freeze the calling script. Any code with a delay
  belongs behind `spawn` or `execVM`, never `call`.
- `remoteExec` targets: `0` = every machine, `-2` = all clients (not
  server), `2` = server only, a specific client's `owner` ID = just that
  client. A `true` fourth argument makes it replay for JIP players.
- WMP's own convention (see `CLAUDE.md`'s "Execution locality" section if
  present in the project) follows exactly this table — nothing WMP-specific
  changes how these four behave, it just picks the right one per script.

## Common error patterns (what they actually mean)

- **`Error Undefined variable in expression`** — almost always one of:
  a genuine typo in the variable name; the variable is `_local` to a
  different scope (e.g. defined inside an `if` block or another script);
  locality (the variable only exists on the machine that set it, e.g. a
  server-only value read on a client); or the script ran **before**
  something else had set it yet — a very common WMP-adjacent case is code
  running before `WALDO_INIT_COMPLETE` is set at the end of `init.sqf`, or
  before `Waldo_fnc_LoadFeatureConfigs` has populated a `MissionConfig`
  default. `isNil "VarName"` (see below) is the fastest way to confirm
  which of these it is.
- **`Error Generic error in expression`** — usually a bracket/paren
  mismatch, a missing comma in an array, or a type mismatch the parser
  can't describe more specifically (e.g. comparing a STRING to a NUMBER).
  Count brackets around the reported line first.
- **`Error Missing ;`** — exactly what it says, but the missing semicolon
  is often on the **line above** the one reported, not the reported line
  itself.
- **`Error Type X, expected Y`** — an engine command got the wrong argument
  type (e.g. passing a STRING where an OBJECT was expected). Check the
  command's biki page (see the lookup table below) for its exact expected
  argument types — don't guess from the command name alone.
- **`Script not found` / file-path errors** — check: correct
  backslashes (`\`, not `/`, in Arma paths), correct case (some platforms/
  packagers are case-sensitive even though Windows usually isn't), and the
  `.sqf` extension is present in the `execVM`/`preprocessFile` call.

## Reading an RPT error block

Cross-reference: see this skill's debugging step for where to find the RPT
file and how to grep it for `[WMP DIAG]` first. This section is just about
reading the raw SQF error block once you have it in front of you.

```
Error in expression <...>
Error position: <...>
  >>>  ...code...  <<<
Error Undefined variable in expression: _foo
File mission\somefile.sqf, line 42
```

- The `>>>` / `<<<` markers bracket the exact token the parser choked on —
  read that fragment first, it's usually more precise than the file/line.
- The reported `line 42` is measured in the **assembled** file after every
  `#include` has been pasted in — for any file that starts with
  `#include` lines (most of `MissionScripts/`), that line number is offset
  from what you'd count reading the source `.sqf` in an editor. Treat the
  reported line as approximate and check the surrounding context, not just
  that exact line in isolation.

## Eden Editor basics relevant to WMP

- **Init field**: SQF that runs once when that specific object initialises.
  Runs for every client (and the server) that has the object local to them
  at that point — not just once mission-wide. Ordering matters: object init
  fields can run **before** `init.sqf` has finished (mission init order is
  not strictly "object inits then init.sqf" or vice versa in every case) —
  if an object's init field calls a WMP function that depends on something
  `init.sqf` sets up (e.g. a `MissionConfig`-loaded default), that's a
  reason a call can fail intermittently. Several WMP functions are
  documented as safe from an object init specifically because they're
  written to tolerate this (see the feature's own reference file for which
  ones).
- **Variable Name field**: gives the placed object a global variable so
  scripts can reference it (`myTruck`, `MHQ_1`, etc.) — required by any WMP
  function/example that references an object by name (MHQ, vehicle camo,
  construction objects, weapon mounting, teleport, and others all depend on
  this).
- **Syncing objects** (right-click → Synchronize): creates an explicit
  engine relationship the *reading* script looks for — e.g. WMP's MHQ,
  vehicle-camo, and construction-object systems all find their
  tent/camo/buildable objects by reading what's synced to a placed Game
  Logic, not by proximity. Sync direction/target matters — several WMP
  gotchas boil down to syncing to the wrong object (see `mhq.md`,
  `misc-mission-maker-tools.md`'s Vehicle Ambush & Camo / Construction
  Objects sections).
- **Game Logic**: an invisible, non-physical placeable object used purely
  as a script anchor/position reference — has no simulation, model, or
  gameplay presence. WMP uses it as the sync target for MHQ, vehicle camo,
  and construction objects, and as the position reference for the map
  location tools.
- **Module attributes vs script config**: a Zeus/Eden *module*'s own
  attribute dialog is a different configuration surface from a
  `MissionConfig\*.sqf` file or a script call — a module's dialog only sets
  values for that one placed module instance, it doesn't touch the shared
  config file. Don't conflate "configure the module's attributes" with
  "edit the config file" when giving instructions.
- **Disabling Binarize**: covered in `loadout-logistics.md` and `SKILL.md`
  — required for `mission.sqm` to be text-readable by WMP's loadout
  scanner. Not repeated here.
- **Waypoints** (only the WMP-relevant basics): a waypoint is an ordered
  behaviour instruction on a group, not an object — `LAND`/`UNLOAD`/
  `TRANSPORT UNLOAD`/`GET OUT` waypoint types are what Improved AI
  Helicopter Landing watches for (see `ai-rebalance.md`); AI Convoy System
  and gunship/transport orbit logic manage vehicle movement independently
  of manually placed waypoints, so adding your own competing waypoint to a
  group already under one of those systems' control is usually the cause
  if movement looks confused (see `misc-mission-maker-tools.md`,
  `gunship.md`, `transport-services.md`).

## Debugging tools

- **`systemChat "text";`** / **`hint "text";`** — quick, visible
  print-debugging. `systemChat` is unobtrusive (side chat), `hint` is a
  large on-screen box — use `hint` sparingly, it interrupts the player.
- **`diag_log "text";`** — writes to the RPT log without showing anything
  on screen; the standard choice for logging that shouldn't clutter chat,
  and works on a dedicated server with no client watching.
- **`-showScriptErrors`** Arma launch parameter — makes SQF errors appear
  as an on-screen popup during testing, not just buried in the RPT. Add it
  to the launch shortcut/Steam launch options while iterating.
- **`isNil "VarName"`** — `true` if a global variable was never set (vs.
  set to a falsy value like `false` or `0`, which is not the same as unset).
  The fastest way to confirm whether an "Undefined variable" error is a
  genuine typo or a real ordering/locality problem.
- **`isNull objectOrGroup`** — `true` if an object/group reference exists
  but points at nothing (deleted, never created, failed spawn) — different
  from `isNil`, which is about the *variable* not existing at all.
- **`typeName value`** — returns the value's type as a string (`"OBJECT"`,
  `"STRING"`, `"ARRAY"`, etc.) — the fastest way to confirm a `Type X,
  expected Y` error's actual cause.
- **Silent failure vs a visible error**: a script can fail "quietly" — a
  guard clause exits with `{}`/`nil`/`false` and nothing appears anywhere,
  which is exactly how most of WMP's own mod-detection guards behave when a
  required mod is missing (see `mod-detection.md`) — versus a genuine SQF
  parse/runtime error, which always writes an RPT entry. If nothing
  happened **and** the RPT is clean, suspect a guard clause / missing
  dependency, not a bug; if the RPT has an error block, work from that
  block per the section above.

## Official lookup pages (when the skill's own knowledge runs out)

It's fine — expected, even — to fetch a specific Bohemia Interactive
Community wiki (biki) page when unsure of a **vanilla Arma command's**
exact signature, return type, or locality, rather than guessing. Same
"don't guess" policy the rest of this skill applies to WMP's own
functions, extended to vanilla engine commands.

| Page | URL | Use it for |
|---|---|---|
| Biki main page | `https://community.bistudio.com/wiki/Main_Page` | General starting point/search |
| Scripting Commands category | `https://community.bistudio.com/wiki/Category:Scripting_Commands` | Every engine command's full page — args, return type, examples, locality |
| A specific command | `https://community.bistudio.com/wiki/<commandName>` | e.g. `https://community.bistudio.com/wiki/setVariable` — the exact page for one command |
| Eden Editor | `https://community.bistudio.com/wiki/Arma_3:_Mission_Editor:_Eden_Editor` | Editor mechanics (init fields, syncing, modules, attributes) |

Only fetch these for genuinely vanilla-engine questions (a bare SQF command,
Eden mechanics) — WMP's own `Waldo_fnc_*` functions and `MissionConfig`
settings are never on the biki, route those to this skill's own
`references/*.md` files or the WMP wiki instead.

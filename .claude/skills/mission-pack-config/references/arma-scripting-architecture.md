# Arma scripting architecture (execution model, locality, events, CfgFunctions)

Scope: **how a mission actually runs** — the execution model, multiplayer
ownership/locality, the event-handler ecosystem, the `CfgFunctions`
preload pattern, and the Eden Editor mechanics that feed into all of it.
This is the "why does this run when it does, and on which machine" file.
For SQF *language* mechanics (types, control flow, scope), see
`references/sqf-language-reference.md`. For *diagnosing* a broken script,
see `references/sqf-debugging.md`. This file is vanilla Arma/SQF only —
WMP's own specific handling of any of this belongs in that feature's own
`references/*.md` file (cross-referenced throughout below).

## Execution model: `call` / `spawn` / `execVM` / `execFSM` / `remoteExec`

| | Runs | Blocks caller? | Scheduled environment? | Returns a value? |
|---|---|---|---|---|
| `call` | Same thread | Yes | **No — unscheduled** | Yes |
| `spawn` | New thread | No | Yes — scheduled | No (returns a script handle) |
| `execVM "file.sqf"` | Compiles + `spawn`s a file | No | Yes — scheduled | No (returns a script handle) |
| `execFSM "file.fsm"` | Runs a compiled FSM (see below) | No | Its own FSM tick, not a scripted thread | No (returns an FSM handle) |
| `remoteExec ["fnc", targets]` | Runs on other machine(s) | No (local side) | Depends on target's own thread | No directly (see JIP/effects note below) |
| `remoteExecCall` | Same as `remoteExec` but only permits functions marked `CBA_fnc`/allowed via `CfgRemoteExec` | No | Same | No |

### Scheduled vs unscheduled — why it actually matters

The **unscheduled** environment (`call`, and any code that runs directly
from an event handler) executes to completion in the *current* game frame
before the engine moves on — no other scheduled script gets CPU time until
it finishes. This is fast and deterministic, but it means:

- `sleep`/`waitUntil` cannot yield control back to the engine from
  unscheduled code — calling either there throws a runtime error (or in
  some engine versions silently misbehaves) rather than "pausing."
- A long-running unscheduled block (a big loop, a large `forEach`) directly
  costs frame time — this is why WMP's performance-audit tooling
  (`CLAUDE.md`'s "Performance regression audit" section) specifically flags
  new unbounded world scans and recurring work: an expensive unscheduled
  block is a frame-rate hit, not just "slow."

The **scheduled** environment (`spawn`, `execVM`, event handlers registered
as scheduled) runs on the engine's own script scheduler, sharing a limited
per-frame time budget across every other scheduled script — the engine can
suspend and resume a scheduled script between statements (this is what
makes `sleep`/`waitUntil` possible at all). The tradeoff is **no execution
timing guarantee**: a scheduled script can be delayed by other scripts
competing for the same budget, so it's the wrong choice for something that
must happen in the exact current frame (e.g. reading state right before an
event handler's default behaviour would otherwise proceed).

Rule of thumb: anything that needs to *wait* (a `sleep`, a polling
`waitUntil`, a long-running loop) belongs behind `spawn`/`execVM`; anything
that must complete synchronously and return a value right now belongs
behind `call`. WMP's own scripts follow exactly this split — see
`CLAUDE.md`'s "Execution locality" section for the pack's own convention
table, which this rule of thumb explains the reasoning behind.

### `remoteExec` targeting semantics

```sqf
[_args, "Waldo_fnc_Something", 0] remoteExec ["call", 0];   // illustrative shape; real calls pass the function name directly
[_args] remoteExec ["Waldo_fnc_Something", 0];              // target 0 = everyone (including the caller's own machine)
[_args] remoteExec ["Waldo_fnc_Something", -2];             // -2 = all clients, NOT the server
[_args] remoteExec ["Waldo_fnc_Something", 2];               // 2 = server only
[_args] remoteExec ["Waldo_fnc_Something", _client];         // a specific client's `owner` player ID = just that machine
[_args] remoteExec ["Waldo_fnc_Something", 0, true];         // 4th arg true = also replay this call for JIP players
```

- A function must be **allowed for remote execution** — either whitelisted
  via `CfgRemoteExec` in `description.ext`, or (the common WMP/CBA case)
  declared with the right access scope when registered under
  `CfgFunctions`. An un-whitelisted function silently fails to remoteExec
  in a default-security mission — this is a common cause of "it works
  locally but not on a dedicated server" reports.
- The **JIP flag** (`true` as the 4th argument) doesn't replay indefinitely
  by default — it replays once for each newly-joining player unless paired
  with a JIP ID/removal call, and only applies to whole-mission broadcasts,
  not calls scoped to a specific client.
- `remoteExec` with the string `"call"`/`"spawn"`/`"hint"` etc. as the
  second array element can also remote-execute a raw **command** (not just
  a registered function) — engine commands allowed for this are more
  restricted by default than functions for security reasons.
- **Effects-only vs return-value:** because `remoteExec` never returns the
  remote machine's result back to the caller, any WMP/CBA API that needs a
  result from another machine uses a different pattern (a callback function
  passed as an argument, or a published `setVariable` the caller then
  reads) — never assume a `remoteExec`'d call can hand a value back
  synchronously.

## `execFSM` and the FSM system (conceptual only)

Arma also has a separate **Finite State Machine** system (`.fsm` files,
edited in a dedicated FSM Editor tool, run with `execFSM`) used for
long-running state-machine-style AI/vehicle behaviour rather than linear
SQF scripts. You are not expected to write one for WMP work — the relevant
fact is that some mods (notably **LAMBS**, see `references/mods/lambs.md`)
implement their AI behaviour as FSMs rather than SQF scripts, which is why
you'll see `.fsm` files mentioned in that mod's own documentation rather
than `Waldo_fnc_*`-style functions.

## The event-handler ecosystem

Three genuinely different systems — don't mix them up when reading or
writing code:

### 1. Vanilla `addEventHandler` / `addMPEventHandler`

Attached to **one specific object/unit**, fires only for engine events on
that exact object:

```sqf
player addEventHandler ["Killed", { params ["_unit", "_killer"]; ... }];
_vehicle addEventHandler ["HandleDamage", { ... }];   // can override/modify default damage handling
_vehicle addEventHandler ["GetIn", { ... }];
```

Common ones: `Killed`, `HandleDamage`, `GetIn`/`GetOut`, `Fired`,
`Respawn`, `Local`/`Deleted`. `addMPEventHandler` is the same idea, scoped
to a smaller multiplayer-relevant subset and guaranteed to fire correctly
across network replication for those specific events (e.g. `MPKilled`,
`MPHit`) — prefer it over the vanilla equivalent for the events it covers
in a networked mission.

### 2. CBA's `CBA_fnc_addEventHandler` / `CBA_fnc_addClassEventHandler`

**Global named events**, not tied to one object — any script anywhere can
fire or listen for the same named event:

```sqf
["MyMod_SomethingHappened", [_arg1, _arg2]] call CBA_fnc_localEvent;   // fire locally
["MyMod_SomethingHappened", { params ["_arg1", "_arg2"]; ... }] call CBA_fnc_addEventHandler; // listen
```

`CBA_fnc_addClassEventHandler` combines this with a class filter — the
callback fires for **any** unit of a given class that triggers a matching
engine event, without manually attaching an event handler to every
individual unit:

```sqf
["CAManBase", "Killed", { params ["_unit"]; ... }] call CBA_fnc_addClassEventHandler;
```

This is how most of WMP itself is built — `initPlayerLocal.sqf`'s respawn
handling and `AISkillAdjustmentSystem.sqf`'s AI initialisation both use
`CBA_fnc_addClassEventHandler` specifically because it covers editor-placed,
Zeus-spawned, and scripted units alike without per-object wiring (see
`CLAUDE.md`'s CBA_A3 section and `references/mods/cba.md` for the
general mechanism).

### 3. Arma's Mission Event Handlers

Mission-wide engine events, not scoped to any single object:

```sqf
addMissionEventHandler ["EntityKilled", { params ["_killed", "_killer", "_instigator"]; ... }];
addMissionEventHandler ["PlayerConnected", { ... }];
```

`EntityKilled` is exactly what WMP's After-Action Report tracking listens
to — see `endex-aar.md`: registering it once on the server is enough
because the event itself fires on every machine that witnesses the kill,
so server-side registration still captures every kill mission-wide (per
`CLAUDE.md`'s AAR description).

## Multiplayer locality — ownership, not just server/client

Several WMP systems (**AI rebalance**, **explosive breaching**, **radio
jamming**) are explicitly designed around the concepts below per
`CLAUDE.md` — understanding this in depth matters if you're extending WMP's
own code, not just configuring it.

- **`isServer`** — `true` only on the machine acting as the (dedicated or
  listen-host) server.
- **`isDedicated`** — `true` only on a dedicated server specifically (no
  rendered game view at all — distinguishes a true dedicated server from a
  listen-host server, which is also `isServer` but has an interface).
- **`hasInterface`** — `true` on any machine with a rendered game view
  (players, a listen host) — `false` on a dedicated server and on a
  headless client. WMP's guard-clause convention
  (`if !(hasInterface) exitWith {};`, per `CLAUDE.md`'s "Guard clauses"
  section) uses this to mean "client-only presentation code."
- **`local object`** / **`local group`** — whether *this specific machine*
  currently owns simulation authority for that object/group. Locality is
  **not fixed at creation** and is not the same thing as "which machine is
  the server" — ownership actively moves during play:
  - AI groups can be handed to a **headless client** to balance server
    load (see `references/headless-client.md`).
  - A vehicle's simulating owner can change when a **player takes the
    driver/gunner/commander seat** — the vehicle becomes local to that
    player's machine for as long as they're crewing it (roughly; exact
    engine rules vary by seat and vehicle type).
  - A unit generally follows whichever machine currently controls it
    (its owning player's machine for a player-controlled unit, or the
    machine that currently "owns" the AI for an AI unit).
- **Why this matters for scripting**: code that mutates an object (deals
  damage, sets AI skill, reads/writes object-scoped `HandleDamage`-style
  state) needs to run on that object's *current* owner, not wherever the
  object happened to be created or wherever the triggering script started —
  a mutation attempted from a non-owning machine can silently no-op or
  produce inconsistent state across clients. This is exactly why WMP's AI
  rebalance and breaching handlers are deliberately **all-machine
  initialisers** (registered identically on server, every client, and
  every headless client) rather than server-only — each machine only acts
  on objects it currently owns, so the system as a whole covers every
  possible owner without needing to track locality centrally. Jamming
  follows a related but distinct pattern: a server-authoritative registry
  (data) paired with client-local radio *engines* that read that registry
  and act only on the local player's own radios (see `jamming.md`).

## `CfgFunctions` — the function-library preload pattern

`class CfgFunctions { ... }` inside `description.ext` (or, as WMP does it,
inside an `#include`d file — `MissionScripts\WaldosFunctions.sqf`) tells
Arma to **compile and register every listed function at mission start**,
under a chosen namespace prefix. This is the general engine mechanism —
WMP's own `Waldo_fnc_FunctionName` convention (`CLAUDE.md`'s "Function
Registration" section) is a direct instance of it, not something WMP
invented:

```cpp
class CfgFunctions {
    class Waldo {
        class SomeCategory {
            file = "MissionScripts\SomeCategory";
            class SomeFunction {};   // becomes Waldo_fnc_SomeFunction, compiled from SomeCategory\fn_someFunction.sqf (or SomeFunction.sqf per the class's own file mapping)
        };
    };
};
```

Practical consequences of this mechanism, beyond WMP's own naming rule:

- Every declared function is **preloaded and callable from anywhere**
  (`[args] call MyPrefix_fnc_MyFunction;`) without a manual
  `compile preprocessFileLineNumbers` at the point of use — this is why
  `Waldo_fnc_*` calls just work throughout the pack with no visible
  compile step.
- The **whole class list compiles at mission start** — a broken function
  file anywhere in the list can produce a compile-time error before the
  mission even loads, not a runtime error later when that specific
  function is finally called. This is a useful diagnostic fact: if a
  mission fails to start entirely with a script error, a recently-added
  `CfgFunctions` entry pointing at a syntactically broken file is a prime
  suspect.
- Adding a mission maker's own function the same way is exactly the "two
  separate steps" rule already stated in `SKILL.md`'s "Rules that apply
  regardless of mode" section (create the `.sqf` file, then add the class
  entry) — that rule is simply this general `CfgFunctions` mechanism
  applied to WMP's own naming convention, not a WMP-specific requirement.

## Config architecture basics (beyond `CfgPatches` mod-detection)

`description.ext` is itself a **config file** — the same class-tree
structure `references/sqf-language-reference.md`'s "Config" section
describes for reading `CfgVehicles`/`CfgWeapons`/etc. at runtime is what
you're *authoring* when you edit `description.ext`. Recognising the
sibling class blocks helps orient a mission maker reading or editing it:

- `class CfgFunctions { ... }` — the function preload list, above.
- `class Header { ... }` — mission metadata (`gameType`, `minPlayers`,
  `maxPlayers` — see `description-ext.md` for WMP's own checklist of which
  fields to touch).
- `class CfgDebriefing { ... }` — custom end-screen definitions (`End1`,
  etc. — see `endex-aar.md`).
- Top-level scalar/string assignments outside any class (`author =`,
  `respawn =`, `respawnDelay =`, `#include` lines) are just properties of
  the implicit root config, the same as any property inside a named class
  block.

All of these compile together as one config tree at mission load — a
syntax error anywhere in `description.ext` (a missing semicolon, an
unbalanced brace in any class block) can prevent the whole mission from
loading, the same way a broken `CfgFunctions` entry can.

## Eden Editor mechanics that feed into all of the above

- **Init field**: SQF that runs once when that specific object initialises.
  Runs independently on every machine (client and server) that has the
  object local to them at that point — not just once mission-wide, and not
  guaranteed to run strictly after `init.sqf` has finished. Object init
  fields can execute **before** `init.sqf` completes (mission init
  ordering is not a strict "object inits, then init.sqf" or vice versa in
  every case) — if an object's init field calls a WMP function that
  depends on something `init.sqf`/`MissionConfig` sets up, that ordering
  ambiguity is a real, reproducible reason a call can fail intermittently.
  Several WMP functions are specifically documented as safe to call from an
  object init because they're written to tolerate this (guard/retry/queue
  internally) — check the feature's own reference file for which ones.
- **Variable Name field**: gives the placed object a global variable so
  scripts can reference it (`myTruck`, `MHQ_1`, etc.) — required by any WMP
  function/example that references an object by name (MHQ, vehicle camo,
  construction objects, weapon mounting, teleport, and others all depend on
  this, per their own reference files).
- **Syncing objects** (right-click → Synchronize): creates an explicit
  engine relationship the *reading* script looks for, distinct from mere
  proximity — WMP's MHQ, vehicle-camo, and construction-object systems all
  find their tent/camo/buildable objects by reading what's synced to a
  placed Game Logic, not by scanning nearby objects. Sync direction/target
  matters — several WMP gotchas boil down to syncing to the wrong object
  (see `mhq.md`, `misc-mission-maker-tools.md`'s Vehicle Ambush & Camo /
  Construction Objects sections).
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
  behaviour instruction on a *group*, not a property of an object —
  `LAND`/`UNLOAD`/`TRANSPORT UNLOAD`/`GET OUT` waypoint types are what
  Improved AI Helicopter Landing watches for (see `ai-rebalance.md`); AI
  Convoy System and gunship/transport orbit logic manage vehicle movement
  independently of manually placed waypoints, so adding a competing
  waypoint to a group already under one of those systems' control is
  usually the cause if movement looks confused (see
  `misc-mission-maker-tools.md`, `gunship.md`, `transport-services.md`).

## See also

- `references/sqf-language-reference.md` — the language itself
- `references/sqf-debugging.md` — diagnosing a broken script, official
  lookup links, and community support sources
- `references/mods/*.md` — the mods WMP depends on, their own execution
  concepts (e.g. LAMBS' FSM-based AI) beyond vanilla Arma

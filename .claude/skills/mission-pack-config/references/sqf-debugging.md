# SQF / Arma debugging (errors, RPT, tools, methodology)

Scope: **diagnosing a broken script or unexpected behaviour** — error
message meanings, reading an RPT log, in-editor debugging tools, and a
general isolation methodology. For SQF *language* mechanics, see
`references/sqf-language-reference.md`. For *how a mission runs*
(execution model, locality, event handlers), see
`references/arma-scripting-architecture.md`. Cross-reference this skill's
own debugging workflow in `SKILL.md`'s "when the user reports something
broken" step for the WMP-specific first moves (grep `[WMP DIAG]`, check
`mod-detection.md`) before falling back to the general material here.

## Common error patterns (what they actually mean)

- **`Error Undefined variable in expression`** — almost always one of:
  a genuine typo in the variable name; the variable is `_local` to a
  different scope (declared inside an `if` block or another script — see
  `sqf-language-reference.md`'s "Scope and declaration" section); locality
  (the variable only exists on the machine that set it, e.g. a
  server-only value read on a client — see `arma-scripting-architecture.md`'s
  locality section); or the script ran **before** something else had set
  it yet — a very common WMP-adjacent case is code running before
  `WALDO_INIT_COMPLETE` is set at the end of `init.sqf`, or before
  `Waldo_fnc_LoadFeatureConfigs` has populated a `MissionConfig` default.
  `isNil "VarName"` (see below) is the fastest way to confirm which of
  these it is.
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
- **`Script not found` / file-path errors** — check: correct backslashes
  (`\`, not `/`, in Arma paths), correct case (some platforms/packagers
  are case-sensitive even though Windows usually isn't), and the `.sqf`
  extension is present in the `execVM`/`preprocessFile` call.

## Reading an RPT error block

Cross-reference: see `SKILL.md`'s debugging step for where to find the RPT
file itself and how to grep it for `[WMP DIAG]` first. This section is
about reading the raw SQF error block once you have it in front of you.

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
  `#include` has been pasted in — for any file that starts with `#include`
  lines (most of `MissionScripts/`), that line number is offset from what
  you'd count reading the source `.sqf` in an editor. Treat the reported
  line as approximate and check the surrounding context, not just that
  exact line in isolation.

## Debugging tools

### Print-style debugging

- **`systemChat "text";`** / **`hint "text";`** — quick, visible
  print-debugging. `systemChat` is unobtrusive (side chat), `hint` is a
  large on-screen box — use `hint` sparingly, it interrupts the player.
- **`diag_log "text";`** — writes to the RPT log without showing anything
  on screen; the standard choice for logging that shouldn't clutter chat,
  and works on a dedicated server with no client watching.

### Performance/state inspection

- **`diag_fps`** / **`diag_fpsMin`** — current and worst-recent frame rate;
  a quick sanity check when something feels laggy before assuming a script
  is the cause.
- **`diag_tickTime`** — engine tick time counter, useful for coarse timing
  comparisons around a suspect block of code (capture it before/after and
  diff).
- **`diag_activeMissionFSMs`** — lists currently running `.fsm` state
  machines (see `arma-scripting-architecture.md`'s FSM note) — relevant if
  a mod like LAMBS is suspected of contributing to a performance issue,
  since its behaviour runs as FSMs rather than visible SQF scripts.
- These are awareness-level tools for this skill's purposes, not a full
  profiling workflow — if a mission maker needs serious performance
  profiling beyond "is something obviously stuck," that's beyond this
  skill's scope; WMP's own `performance_audit.py` (dev-repo only, see
  `CLAUDE.md`) is a static analysis tool, not a runtime profiler.

### `isNil` / `isNull` / `typeName`

- **`isNil "VarName"`** — `true` if a global variable was never set (vs.
  set to a falsy value like `false` or `0`, which is **not** the same as
  unset). The fastest way to confirm whether an "Undefined variable" error
  is a genuine typo or a real ordering/locality problem. `isNil` also
  accepts a CODE block form (`isNil { someExpression }`) to safely probe
  an expression that might itself error.
- **`isNull objectOrGroup`** — `true` if an object/group reference exists
  but points at nothing (deleted, never created, failed spawn) — different
  from `isNil`, which is about the *variable* not existing at all. A
  variable can be non-nil and hold a null object at the same time.
- **`typeName value`** — returns the value's type as a string (`"OBJECT"`,
  `"STRING"`, `"ARRAY"`, etc.) — the fastest way to confirm a `Type X,
  expected Y` error's actual cause.

### The in-editor Debug Console (Zeus / Eden)

Both Eden Editor's preview mode and a running Zeus session expose a
built-in **Debug Console** — the actual first tool most mission makers
reach for before ever opening an RPT file:

- Lets you type and immediately execute an SQF expression against a chosen
  **execution target**: `player` (runs as if from the current player's own
  script context), `server`, or a specific unit/machine — this directly
  exercises the locality concepts in `arma-scripting-architecture.md`, so
  it's a fast way to confirm "does this value exist on the server vs a
  client" without writing a throwaway script file.
  `local exec`/`global exec`-style options (naming varies slightly by
  Eden/Zeus version) choose whether the typed code runs only where you
  triggered it or is broadcast.
- Accessible from Eden's own toolbar during a preview run, and from Zeus's
  interface during a live session (curator permission required in a
  multiplayer session — the same curator-only gate several WMP Zeus
  modules already enforce, per each feature's own reference file).
- Good for: checking a variable's current value mid-mission, manually
  calling a WMP function once to see what happens, confirming an object
  exists/is local before writing a real fix.
- Not a substitute for the RPT when the problem is a genuine script error
  that already happened — the console only tells you about code you type
  into it right now.

## How to isolate a problem (general methodology, not WMP-specific)

1. **Reproduce with the smallest possible repro.** Strip the scenario down
   to the one object/script/call that's actually misbehaving before trying
   to fix anything — a whole mission is too large a surface to reason
   about at once.
2. **Bisect by commenting out.** If a mission fails to load or a script
   errors immediately, comment out recently-added `#include`s, `CfgFunctions`
   entries, or init-field calls one at a time (or in halves, then narrow)
   until the error disappears — the last thing removed before it clears is
   the culprit, or at minimum where to look closer.
3. **Test in the editor preview before a dedicated server.** Eden's own
   preview mode is faster to iterate in and gives you the Debug Console —
   confirm basic behaviour there before testing on a full dedicated server
   setup, which adds headless-client/locality variables that can obscure a
   simpler root cause.
4. **Reproduce with a minimal standalone script** when the suspect code is
   deeply embedded in a larger system — paste just the failing expression
   into the Debug Console or a throwaway `execVM`'d file with hard-coded
   test values, rather than debugging it in place inside a much larger
   call chain.
5. Once you've isolated *which* WMP feature (if any) is actually involved,
   stop using this file and route to that feature's own `references/*.md`
   for its exact expected behaviour/gotchas — this file is about the
   general technique, not a substitute for the per-feature reference.

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
| Functions Viewer / `CfgFunctions` category | `https://community.bistudio.com/wiki/Category:Arma_3:_Functions` | Vanilla `BIS_fnc_*` function library reference — the vanilla-engine counterpart to WMP's own `Waldo_fnc_*` library, and the `CfgFunctions` mechanism itself |

Only fetch these for genuinely vanilla-engine questions (a bare SQF
command, Eden mechanics) — WMP's own `Waldo_fnc_*` functions and
`MissionConfig` settings are never on the biki, route those to this
skill's own `references/*.md` files or the WMP wiki instead. For a
specific *mod's* own API (ACE, ACRE2, ZEN, etc.) beyond the biki's
vanilla-engine scope, see `references/mods/*.md`.

## Community support beyond official docs

For a scripting question the biki doesn't answer directly, the **Bohemia
Interactive Forums** and the **r/armadev** community (Reddit) are common
places mission makers get help — mentioned here as known, stable community
hubs, not as a specific fetchable page. Don't invent a specific thread URL
or claim to have searched either unless you actually did (via live
browsing, if available) — point the user at the community by name and let
them search, the same way `references/mods/*.md` handles uncertain
mod-specific links.

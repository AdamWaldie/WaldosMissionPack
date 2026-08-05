---
name: mission-pack-config
description: Configures WaldosMissionPack (WMP) — the Arma 3 mission scripting starter framework in this repo — for a specific mission, and answers "how do I..." / "how does X work" questions about using it. Covers every WMP system — loadout/logistics, AI rebalance, ACRE2 radio setup, paradrop, radio jamming/EMP/signal trackers, MHQ, respawn options, ENDEX/AAR, safestart, mission diagnostics, tasks/objectives, VVD, Zeus Enhanced modules, the Waldos Economy Systems suite, table minigames, interaction minigames, UI notifications, WMP HUD, transport services, hazardous environments, tree felling, breaching, Dynamic AA/AO, gunship support, persistence, object scaling, emergency dismount, tactical display, field resupply, vehicle recovery/rally points, UI themes, corpse traps, 3D markers, and the description.ext mission-maker checklist. Use this whenever the user wants to set up, enable, tune, or debug any WMP feature, wants "a mission configured with X", asks what a WMP variable or function does, asks how to use a feature as a player/curator/mission maker, or is editing MissionConfig/*.sqf, init.sqf/initServer.sqf/initPlayerLocal.sqf/description.ext for this pack — even if they only name one feature, since features interact (e.g. ACRE2 setup depends on mission.sqm loadouts, Economy depends on Zeus Enhanced). Always check this skill before hand-writing WMP config or usage guidance from memory — the reference files (and the wiki) are the faithful, current spec.
---

# WMP Mission Pack Configuration

You are configuring WaldosMissionPack for a real mission. **Assume by default
that you are working inside someone's own mission project, not the WMP
development repo** — the normal user of this skill downloaded a WMP release
zip and dropped its contents into their own `.vr`/`.altis`/etc. mission
folder in Eden Editor. That has real consequences:

- The mission folder will **not** contain `releaseVerificationAndDeployment/`
  or any of its validators — that whole folder is dev tooling explicitly
  excluded from every release build. Never assume `sqf_validator.py`,
  `config_style_checker.py`, or `performance_audit.py` exist or can be run;
  check before referencing them, and only expect them if you can confirm
  you're actually inside the WMP dev repo itself (e.g. this repo).
- **`mission.sqm` is never edited directly, by anyone, under any
  circumstance.** It is Eden Editor's own saved binary-adjacent project
  file; WMP only *reads* it at mission start to scrape loadouts. Every
  change that touches it — placing objects, editing unit loadouts in ACE
  Arsenal, syncing a Game Logic, moving something in 3D space, disabling
  Binarize — is exclusively an Eden Editor GUI action for the user to
  perform. This is instruction mode, always, with no exceptions.

## The MissionConfig model — read this before touching any variable

Mission-maker configuration lives in semantic, pure-data files under
**`MissionConfig\`**: `acreConfig.sqf`, `aiConfig.sqf`,
`airOperationsConfig.sqf`, `economyConfig.sqf`, `electronicWarfareConfig.sqf`,
`environmentConfig.sqf`, `interfaceConfig.sqf`, `logisticsConfig.sqf`,
`missionSystemsConfig.sqf`, `persistenceConfig.sqf`, and the infrastructure-only
`featureConfigManifest.sqf`. Each returns a HashMap of `shared` (every
machine, loaded from `init.sqf`), `server` (loaded by `initServer.sqf`,
optionally JIP-published), and `playerLocal` (loaded by `initPlayerLocal.sqf`)
rows — see `wiki/Feature-Configuration-Files.md` and
`wiki/Mission-Configuration-Reference.md` if you need the full loader schema.

This means the three Arma init files (`init.sqf`, `initServer.sqf`,
`initPlayerLocal.sqf`) are now **narrow, lifecycle-only** files: activation,
authority, JIP handling, and pre-planned world setup (registering a Dynamic
AA system, a gunship, a recovery workshop, etc.) — almost never a *value* to
tweak. **When a reference file below tells you to edit a
`MissionConfig\*.sqf` setting, do that — don't paste a `setVariable` call
into an init file "to be safe."** The one systemic exception mission makers
still touch directly in an init file: pre-planned `initServer.sqf` setup
calls for call-driven/enable+register features (Dynamic AA, gunship,
paradrop drop zones, recovery workshops, hazard zones, persistence object
registration — see `wiki/Feature-Setup-and-Activation.md`'s "where custom
calls belong" table) and the couple of genuinely-still-commented-out
`initPlayerLocal.sqf` event-handler snippets (`respawn.md`).

Config comments use three labels — mirror this distinction when advising a
user, don't casually recommend changing an ADVANCED value:

| Label | Meaning |
|---|---|
| **MISSION MAKER** | Review per mission — enablement, content, sides, names, player-facing behaviour |
| **ADVANCED TUNING** | Supported, but normally keep the shipped value; change only for a tested requirement |
| **COMPATIBILITY** | Parser/legacy support — never touch for ordinary configuration |

Mission makers using this pack are not scripters — they configure it through
`MissionConfig` files, the (now narrower) init files, and Eden Editor, so
precision matters more than cleverness: get variable names, function
signatures, and defaults exactly right by reading the reference file for the
feature in question rather than recalling it. `CLAUDE.md` at the WMP dev
repo's root predates this MissionConfig migration and several newer features
in places — **treat the wiki and `MissionConfig/*.sqf` as more current than
`CLAUDE.md` wherever they disagree** (you may not have `CLAUDE.md` available
at all from inside a user's mission project — that's what `references/` is
for). The files under `references/` are condensed, faithful extracts from
the wiki/`MissionConfig`, split per feature so you don't have to load a
1000-line file for a one-feature request.

## The wiki is a live reference, not a last resort

The WMP wiki (https://github.com/AdamWaldie/WaldosMissionPack/wiki — or the
local `wiki/*.md` checkout when you're working inside the dev repo) is the
**fullest and most current** source, ahead of even a freshly-updated
`references/` file for edge cases. Treat consulting it as a normal part of
this skill's workflow, not something you reach for only when stuck:

- **`wiki/Home.md`** and **`wiki/Feature-Catalogue.md`** are the natural
  orientation entry points — use them to find a feature's proper page name
  when a `references/*.md` file doesn't cover something, or to sanity-check
  that you have the full current feature list.
- Whenever a `references/*.md` file leaves something vague, doesn't fully
  answer the question, or you want to double-check current behaviour before
  giving exact variable names/params to a mission maker, fetch the matching
  wiki page. This applies in **Q&A mode** especially — a "how does X work"
  question deserves a wiki-verified answer, not a paraphrase from memory of
  the condensed reference file.
- If you can't fetch it (no browsing tool, or you're the ChatGPT wrapper —
  see `chatgpt/INSTRUCTIONS.md`), say plainly that you're working from the
  condensed reference file only and could be missing recent detail, rather
  than presenting it as exhaustive.

## Step 1: work out what you're actually able to do here

Before touching any feature, decide which of the three output modes applies —
this determines the *shape* of everything you produce, so get it right first:

1. **Direct-edit mode** — you have file-edit tools (Edit/Write) and a shell
   against the user's actual mission project folder. Edit the relevant
   `MissionConfig\*.sqf` file directly for settings, or `init.sqf`,
   `initServer.sqf`, `initPlayerLocal.sqf`, `description.ext` for genuine
   lifecycle/pre-planned-setup code, then do the post-edit check in Step 5
   (which validators to run, if any, depends on what's actually present in
   that folder — don't assume).
2. **Patch mode** — you can see the files (or the user pasted their file
   contents into chat) but have no execution tool, or editing isn't
   appropriate yet (e.g. you're drafting for review). Produce exact snippets
   plus a precise insertion point: which file, and which existing line/block
   the snippet goes after or replaces. Never say "add this to
   `MissionConfig\aiConfig.sqf`" without saying *where* — mission makers
   will not know where a setting like `Waldo_AIRebalance_Enable` or
   `Waldo_Economy_Enable` already has a home in that file's `shared`/`server`
   array.
3. **Instruction mode** — always applies on top of the other two, for the
   steps in Arma itself that no assistant can perform, chief among them
   anything touching `mission.sqm`: placing objects and Game Logics in Eden
   Editor, syncing objects, editing unit loadouts in ACE Arsenal, unchecking
   mission Binarize, saving the mission. Also covers clicking a Zeus module
   in a running mission. State these as a numbered checklist and do not
   imply you've done them — you never edit `mission.sqm`, in any mode.

If you're running as the ChatGPT wrapper (see `chatgpt/INSTRUCTIONS.md`),
direct-edit mode is never available — you only have patch + instruction mode,
and you'll need to ask the user to paste their current file contents before
you can give a precise insertion point.

4. **Q&A mode** — the user isn't asking you to touch any file at all, just
   "how do I plant a signal tracker", "how does jamming falloff work", "what
   does the Zeus Fortify Budget module do", "how do players respawn with
   their gear". Nothing to edit or patch here — just answer from the
   relevant `references/*.md` file(s) (and `CLAUDE.md`/the wiki if
   available), citing the actual variable/function names and Zeus module
   names rather than paraphrasing loosely. This covers players and curators
   asking about in-game usage, not just mission makers configuring files.
   Still route through Step 3 below to find the right reference file(s)
   first, and prefer the live wiki over the condensed file when precision
   matters (see above).

## Step 2: find out what's actually in play

Many WMP features silently no-op without their mod — spending effort
configuring ACRE2 channels for a unit that doesn't have ACRE2 is wasted work,
and the user may not think to mention it. Read `references/mod-detection.md`
and either check the repo (mod-dependent code is always guarded by a
`CfgPatches` check — grep for it) or ask the user directly:

- CBA_A3 and ACE3 are **required** — assume present.
- ACRE2, TFAR, Zeus Enhanced (ZEN), LAMBS are **optional** — ask, or check
  what the user's `@mods` list / server config implies.

Also confirm which config layer you're actually looking at before proposing
an edit: `MissionConfig\*.sqf` for settings, the narrow init files only for
lifecycle/pre-planned-registration code (see "The MissionConfig model"
above) — don't assume an older mission project still uses the pre-migration
pattern (a direct `setVariable`/inline call in an init file) without
checking; if you find that older pattern, say so and offer to help port it
to the current `MissionConfig` model rather than silently layering a new
setting on top of stale code.

Also ask (or infer from the request) which features they actually want
configured. Don't silently configure the whole pack when they asked for one
thing — but do mention features that depend on what they're touching (e.g.
if they're setting up loadout crates, mention that ACE Arsenal editing of
unit loadouts in Eden, not vanilla loadouts, is what feeds the crates).

## Step 3: route to the feature reference

Each file below is a condensed spec for one system: its config variables and
defaults, its callable functions and params, the Zeus module(s) if any, and
its known gotchas. Read only the ones relevant to the request. If a request
sits between two rows, or the row's "Notes" column flags a dependency, read
both. When precision matters beyond what's here, consult the live wiki (see
above) — its `Home.md`/`Feature-Catalogue.md` pages are the fastest way to
find a page this table doesn't name explicitly.

| Feature | Reference | Notes |
|---|---|---|
| Loadout & logistics (supply/medical crates, mission.sqm scraping) | `references/loadout-logistics.md` | Everything else depends on this |
| AI rebalance (profiles + improved AI helicopter landing) | `references/ai-rebalance.md` | |
| ACRE2 radio setup (nets/groups/Babel) | `references/acre2.md` | Requires mod; full net/group model, not the old array |
| Paradrop / Dynamic Drop Zone Operations | `references/paradrop.md` | Automatic per-vehicle actions + server-owned drop-zone system |
| Radio jamming (ACRE2 + TFAR) | `references/jamming.md` | Now includes RDF bands and the disable-challenge model |
| EMP burst | `references/emp.md` | |
| Signal trackers (C-Track) | `references/trackers.md` | |
| MHQ / mobile command post | `references/mhq.md` | Eden Editor placement + sync required |
| Respawn options | `references/respawn.md` | Never touch `respawnOnStart` |
| ENDEX / After-Action Report | `references/endex-aar.md` | |
| Safestart | `references/safestart.md` | Default changed: starts inactive unless configured |
| Mission diagnostics | `references/diagnostics.md` | Grep RPT for `[WMP DIAG]` when debugging anything |
| Tasks / objectives helper | `references/tasks.md` | |
| Virtual Vehicle Depot (VVD) | `references/vvd.md` | WIP — warn the user |
| Zeus Enhanced modules (registration overview) | `references/zeus-modules.md` | Routes to the per-feature file for each module's detail |
| Waldos Economy Systems (Resource/Research/Build/Buy + Command) | `references/economy/README.md` → sub-files | Large — only load the sub-namespace(s) needed |
| Table minigames + interaction minigames | `references/minigames.md` | Points to `corpse-traps.md` for the related-but-separate system |
| UI notifications / recovery | `references/ui-notifications.md` | |
| `description.ext` mission-maker checklist | `references/description-ext.md` | |
| WMP HUD (friendly 3D identification) | `references/wmp-hud.md` | |
| Helicopter/ground transport services | `references/transport-services.md` | |
| Hazardous environments (contamination/toxic/etc.) | `references/hazardous-environments.md` | |
| Tree felling | `references/tree-felling.md` | Arma has no vanilla axe — needs a mod weapon |
| Explosive wall breaching | `references/breaching.md` | Requires ACE Explosives |
| Dynamic Anti-Air | `references/dynamic-aa.md` | |
| Dynamic AO Generation | `references/dynamic-ao.md` | No `MissionConfig` file — call/ZEN only |
| Airborne Gunship Support | `references/gunship.md` | |
| INIDBI2 persistence | `references/persistence.md` | Requires server-side INIDBI2 extension |
| Object scaling / transforms | `references/object-scaling.md` | |
| Emergency dismount | `references/emergency-dismount.md` | Intentionally no ZEN module |
| Tactical display | `references/tactical-display.md` | Needs a map-board-style object, not any object |
| Field resupply | `references/field-resupply.md` | |
| Patient treatment feedback | `references/medical-feedback.md` | Requires ACE medical |
| Vehicle recovery + squad rally points | `references/vehicle-recovery-rallies.md` | Two related but independent systems |
| UI visual themes + colour-vision accessibility | `references/ui-themes.md` | Theme is mission-wide; colour-vision is per player, never set it globally |
| ACE Corpse Traps | `references/corpse-traps.md` | |
| Headless client + player markers | `references/headless-client.md` | Still plain `execVM`, no `MissionConfig` file |
| Custom 3D world markers | `references/3d-markers.md` | No `MissionConfig` file — pure call API |
| Misc mission-maker tools (AI convoy, map locations, vehicle camo, teleport, weapon mounting, construction objects, ACE Fortify, radio reports, team colour) | `references/misc-mission-maker-tools.md` | Compact catch-all — one short subsection each |
| Vanilla SQF/Arma engine mechanics (not WMP-specific) | `references/sqf-arma-basics.md` | Debugging support — syntax recap, error-message meanings, Eden basics, official biki lookup links |

## Step 4: when the user reports something broken, not something to configure

If the request is "X isn't working" / "I got an error" / "this behaves
unexpectedly" rather than "help me configure X," triage before jumping to a
reference file's config section:

1. **Ask for the RPT log if it wasn't already provided**, and explain where
   to find it if the user doesn't know:
   - Windows client default: `%localappdata%\Arma 3\<profile name>.rpt`
     (or wherever `-profiles=` points, if the launch shortcut customises it).
   - A **dedicated server**'s RPT lives in the server's own profile folder,
     not the client's — ask which one is relevant if the report could be
     either.
   - Mod/addon load errors (missing dependency, `CfgPatches` conflict, a
     broken `config.cpp`) typically appear near the **top** of the log, at
     mission/addon load, before mission scripts even run.
2. **Grep it for `[WMP DIAG]` first** — see `references/diagnostics.md`.
   WMP's own startup diagnostics self-report common misconfigurations
   (missing mod, unconfigured classname, disabled feature that looks
   broken) in a searchable frame
   (`[WMP DIAG][run=...][node=...][area=...][feature=...][level=...][event=...]`),
   so this is often faster than reading the whole RPT by hand.
3. **When reading a pasted RPT excerpt**, look for `Error in expression`,
   the script filename on the line above/below it, and the line marked with
   `>>>` pointing at the exact token. SQF errors report a file+line, but in
   `#include`-assembled files (most of `MissionScripts/`) that line number
   can be offset from what you'd expect reading the source file directly —
   check the surrounding context, not just the reported line in isolation.
   **For what a specific error message actually means** ("Undefined
   variable", "Generic error", "Missing ;", "Type X, expected Y", a
   `Script not found` path error) see `references/sqf-arma-basics.md`'s
   "Common error patterns" and "Reading an RPT error block" sections —
   don't guess at the cause from the message alone.
4. **Check `references/mod-detection.md` before assuming a bug.** The
   single most common "why isn't this doing anything" cause across the pack
   is a missing-mod guard clause silently no-op'ing (no error, no chat
   message, nothing) — ACRE2/TFAR/ZEN absent, or a signal-model mismatch for
   jamming. Confirm the required mod is actually loaded and active before
   troubleshooting further. `references/sqf-arma-basics.md`'s "silent
   failure vs a visible error" note explains why a clean RPT with nothing
   visibly happening points here rather than at a script bug.
5. Once you've identified the actual feature involved, route through **Step
   3**'s table as normal for that feature's exact config/gotchas — this
   triage step is about gathering the right information first, not a
   replacement for the per-feature reference.

## Basic SQF/Arma engine questions and vanilla-command lookups

If a mission maker asks a basic SQF syntax or Eden Editor question that's
incidental to configuring WMP — "what's the difference between `call` and
`spawn`", "how do I open the RPT log", "how do I sync two objects in Eden",
"why does Arma say my bracket count is wrong", "what does `setVariable`
return" — this is now a proper reference file, not just an inline
allowance: **`references/sqf-arma-basics.md`**. It covers core syntax
(statement termination, `_local` vs global vars, `missionNamespace`,
`params`, and a `call`/`spawn`/`execVM`/`remoteExec` comparison table with
why `sleep`/`waitUntil` need a scheduled environment), common error-message
meanings (tied into the debugging step above), the Eden Editor mechanics
WMP actually touches (init fields and their ordering pitfalls, Variable
Name, syncing, Game Logic, module attributes vs script config), and
print-debugging tools (`systemChat`/`hint`/`diag_log`,
`-showScriptErrors`, `isNil`/`isNull`/`typeName`).

It also carries the **official Bohemia Interactive Community wiki (biki)
lookup table** — the biki main page, the Scripting Commands category, and
the Eden Editor page — plus explicit permission to fetch a specific
`https://community.bistudio.com/wiki/<commandName>` page when unsure of a
**vanilla** Arma command's exact signature, return type, or locality,
rather than guessing. This is the same "don't guess" policy the rest of
this skill applies to WMP's own functions, just extended to vanilla engine
commands — use it, don't recall a command's behaviour from memory when the
page is one fetch away.

Keep this skill's centre of gravity on **WMP itself**: that reference file
is scoped to debugging/understanding vanilla mechanics that come up while
using WMP, not a full scripting course. Any WMP-specific variable,
function, or error still routes to that feature's own `references/*.md`
file first — don't answer a WMP question out of `sqf-arma-basics.md`, and
don't turn a one-line syntax question into a general SQF tutorial or treat
an unrelated pasted script as something this skill should review.

## Step 5: after editing (direct-edit mode only)

Check first whether `releaseVerificationAndDeployment/` actually exists in
the project you're editing — it ships only in the WMP *development* repo,
never in a release zip, so it usually won't be there in a mission maker's
own project. If it's present:

```bash
python3 releaseVerificationAndDeployment/sqf_validator.py
python3 releaseVerificationAndDeployment/config_style_checker.py
```

and, if you added or changed anything that loops, polls, or broadcasts
repeatedly (a `waitUntil`, a `spawn` with a `while {true}`, a `remoteExec`
inside a loop):

```bash
python3 releaseVerificationAndDeployment/performance_audit.py
```

Report validator output to the user rather than assuming success. If a
validator fails, fix the underlying issue (tabs, missing semicolons, bracket
mismatch) — don't work around it.

If those scripts aren't present (the normal case for an end-user mission),
there's no automated safety net — self-check by eye against the conventions
above before telling the user the edit is done: no tab characters, every
statement ends `;`, brackets/braces balance, and the file still has its
header docblock if you added one. Say plainly that you couldn't run the
pack's own validators, so a manual read of the changed section in-editor is
still worth doing.

## Rules that apply regardless of mode

- **Never edit `mission.sqm`.** Not as a "quick fix," not to "just add one
  object." Any change to it is an Eden Editor GUI action for the user —
  route it through instruction mode, always.
- **Never change `respawnOnStart`** in `description.ext` — it must stay `-1`;
  the loadout-saving system depends on it.
- **New `.sqf` files** should keep the standard header docblock (Author /
  one-line description / Arguments with types+defaults / Return Value /
  Example) — copy the format from any existing script under
  `MissionScripts/`. If the file starts with `#include` lines, the header
  goes *after* them. This is good practice in any mission project, not just
  the WMP dev repo.
- **New functions you want auto-preloaded** need a matching class entry in
  `MissionScripts/WaldosFunctions.sqf` (`class Waldo { ... }`, following the
  `Waldo_fnc_FunctionName` naming convention) — registration and file
  creation are two separate steps, do both. A script called directly from an
  object's init field doesn't need this.
- **The CLAUDE.md/README/wiki documentation standard is a WMP-dev-repo-only
  concern.** It only applies if you happen to be working inside the actual
  WMP development repository (this repo) and are adding a genuinely new
  feature to the pack itself — not when you're configuring an existing
  feature for someone's mission, and not when those files don't exist in the
  project you're in at all (the normal case for an end user's mission).
- **Global state** lives in `missionNamespace` via
  `setVariable ["Name", value, true]` (the `true` broadcasts to clients) —
  keep the existing prefix convention (`Waldo_` general, `Logi_` logistics,
  `WALDO_` all-caps for flags/thresholds) rather than inventing a new one.
- **New settings belong in the appropriate `MissionConfig\*.sqf` file as
  pure data** — not hardcoded inside `MissionScripts/` implementation files,
  and not as loose `setVariable` calls scattered through the init files.
  Genuinely one-off, pre-planned world setup (registering a specific
  Dynamic AA system, gunship, or recovery workshop for this exact mission)
  still belongs in `initServer.sqf` or a supported object init, per
  `wiki/Feature-Setup-and-Activation.md`.

## When you're unsure

If a reference file doesn't cover something the user is asking about, or
you're not confident a variable/function still exists as described,
consult the live wiki (see above) or `CLAUDE.md` directly (or grep the
actual `.sqf` under `MissionScripts/`) rather than guessing — mission makers
copy what you give them verbatim into a live mission, and a wrong classname
or param order fails silently or breaks a briefing at the worst time. Still
say plainly when even that doesn't resolve it, rather than inventing a
classname, function signature, or param order.

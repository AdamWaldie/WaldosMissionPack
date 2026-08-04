---
name: mission-pack-config
description: Configures WaldosMissionPack (WMP) — the Arma 3 mission scripting starter framework in this repo — for a specific mission, and answers "how do I..." / "how does X work" questions about using it. Covers every WMP system — loadout/logistics, AI rebalance, ACRE2 radio setup, paradrop, radio jamming/EMP/signal trackers, MHQ, respawn options, ENDEX/AAR, safestart, mission diagnostics, tasks/objectives, VVD, Zeus Enhanced modules, the Waldos Economy Systems suite, table minigames, interaction minigames, UI notifications, and the description.ext mission-maker checklist. Use this whenever the user wants to set up, enable, tune, or debug any WMP feature, wants "a mission configured with X", asks what a WMP variable or function does, asks how to use a feature as a player/curator/mission maker, or is editing init.sqf/initServer.sqf/initPlayerLocal.sqf/description.ext/economyConfig.sqf for this pack — even if they only name one feature, since features interact (e.g. ACRE2 setup depends on mission.sqm loadouts, Economy depends on Zeus Enhanced). Always check this skill before hand-writing WMP config or usage guidance from memory — the reference files (and the wiki) are the faithful, current spec.
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

Mission makers using this pack are not scripters — they configure it through
init files and Eden Editor, so precision matters more than cleverness: get
variable names, function signatures, and defaults exactly right by reading
the reference file for the feature in question rather than recalling it.
`CLAUDE.md` at the WMP dev repo's root is the ultimate source of truth (you
may not have access to it from inside a user's mission project — that's what
the `references/` files are for); the files under `references/` are
condensed, faithful extracts from it, split per feature so you don't have to
load a 1000-line file for a one-feature request. If you do have `CLAUDE.md`
available and it disagrees with a reference file, `CLAUDE.md` wins — treat
that as a sign the reference file has drifted and needs updating.

## Step 1: work out what you're actually able to do here

Before touching any feature, decide which of the three output modes applies —
this determines the *shape* of everything you produce, so get it right first:

1. **Direct-edit mode** — you have file-edit tools (Edit/Write) and a shell
   against the user's actual mission project folder. Edit `init.sqf`,
   `initServer.sqf`, `initPlayerLocal.sqf`, `description.ext`, or
   `MissionConfig/economyConfig.sqf` directly, then do the post-edit check in
   Step 4 (which validators to run, if any, depends on what's actually
   present in that folder — don't assume).
2. **Patch mode** — you can see the files (or the user pasted their file
   contents into chat) but have no execution tool, or editing isn't
   appropriate yet (e.g. you're drafting for review). Produce exact snippets
   plus a precise insertion point: which file, and which existing line/block
   the snippet goes after or replaces. Never say "add this to init.sqf"
   without saying *where* — mission makers will not know where variables like
   `Waldo_AIRebalance_Enable` or `Waldo_Economy_Enable` already have a home.
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
   relevant `references/*.md` file(s) (and `CLAUDE.md` if available), citing
   the actual variable/function names and Zeus module names rather than
   paraphrasing loosely. This covers players and curators asking about
   in-game usage, not just mission makers configuring init files. Still
   route through Step 3 below to find the right reference file(s) first.

## Step 2: find out what's actually in play

Many WMP features silently no-op without their mod — spending effort
configuring ACRE2 channels for a unit that doesn't have ACRE2 is wasted work,
and the user may not think to mention it. Read `references/mod-detection.md`
and either check the repo (mod-dependent code is always guarded by a
`CfgPatches` check — grep for it) or ask the user directly:

- CBA_A3 and ACE3 are **required** — assume present.
- ACRE2, TFAR, Zeus Enhanced (ZEN), LAMBS are **optional** — ask, or check
  what the user's `@mods` list / server config implies.

Also ask (or infer from the request) which features they actually want
configured. Don't silently configure the whole pack when they asked for one
thing — but do mention features that depend on what they're touching (e.g.
if they're setting up loadout crates, mention that ACE Arsenal editing of
unit loadouts in Eden, not vanilla loadouts, is what feeds the crates).

## Step 3: route to the feature reference

Each file below is a condensed spec for one system: its config variables and
defaults, its callable functions and params, the Zeus module(s) if any, and
its known gotchas. Read only the ones relevant to the request.

| Feature | Reference | Notes |
|---|---|---|
| Loadout & logistics (supply/medical crates, mission.sqm scraping) | `references/loadout-logistics.md` | Everything else depends on this |
| AI rebalance (day/night skill profiles) | `references/ai-rebalance.md` | |
| ACRE2 radio setup | `references/acre2.md` | Requires mod; depends on loadout system for group names |
| Paradrop (HALO / static-line) | `references/paradrop.md` | |
| Radio jamming (ACRE2 + TFAR) | `references/jamming.md` | |
| EMP burst | `references/emp.md` | |
| Signal trackers (C-Track) | `references/trackers.md` | |
| MHQ / mobile command post | `references/mhq.md` | Eden Editor placement + sync required |
| Respawn options | `references/respawn.md` | Never touch `respawnOnStart` |
| ENDEX / After-Action Report | `references/endex-aar.md` | |
| Safestart | `references/safestart.md` | |
| Mission diagnostics | `references/diagnostics.md` | |
| Tasks / objectives helper | `references/tasks.md` | |
| Virtual Vehicle Depot (VVD) | `references/vvd.md` | WIP — warn the user |
| Zeus Enhanced modules (registration overview) | `references/zeus-modules.md` | |
| Waldos Economy Systems (Resource/Research/Build/Buy + Command) | `references/economy/README.md` → sub-files | Large — only load the sub-namespace(s) needed |
| Table minigames + interaction minigames | `references/minigames.md` | |
| UI notifications / recovery | `references/ui-notifications.md` | |
| `description.ext` mission-maker checklist | `references/description-ext.md` | |

## Step 4: after editing (direct-edit mode only)

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
below before telling the user the edit is done: no tab characters, every
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
- Configuration belongs in the init files (`init.sqf` shared, `initServer.sqf`
  server-only, `initPlayerLocal.sqf` per-player) or `MissionConfig/economyConfig.sqf`
  — never hardcode mission-specific values inside `MissionScripts/` implementation
  files themselves.

## When you're unsure

If a reference file doesn't cover something the user is asking about, or
you're not confident a variable/function still exists as described, read the
relevant section of `CLAUDE.md` directly (or grep the actual `.sqf` under
`MissionScripts/`) rather than guessing — mission makers copy what you give
them verbatim into a live mission, and a wrong classname or param order fails
silently or breaks a briefing at the worst time.

For pure usage/"how do I" questions specifically, the WMP wiki
(https://github.com/AdamWaldie/WaldosMissionPack/wiki) has per-feature
tutorial pages (setup → usage/options → examples) written for mission makers
rather than scripters, plus dedicated hub pages for larger systems (Waldos
Economy Systems, Zeus module parity, mission diagnostics). If you can fetch
it, prefer it over guessing for anything the `references/*.md` files and
`CLAUDE.md` leave vague — and still say plainly when even that doesn't
resolve it, rather than inventing a classname, function signature, or param
order.

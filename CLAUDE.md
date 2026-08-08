# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

WaldosMissionPack (WMP) is an **Arma 3 mission scripting starter framework**. It is not a traditional software project — it is a drop-in collection of SQF scripts, config files, and tooling that Arma 3 mission makers use to get automated logistics, radio setup, paradrop, AI tuning, Zeus modules, and other features without writing those systems from scratch. It is designed to ease new mission makers into the craft.

The pack is used by 40+ milsim units. Mission makers are the primary audience — they configure the scripts through the init files and Eden Editor, not by writing new code.

**Required Arma 3 mods:** CBA_A3, ACE 3  
**Optional:** ACRE 2, TFAR, Zeus Enhanced, LAMBS series

**Wiki (feature and Zeus module tutorials):** https://github.com/AdamWaldie/WaldosMissionPack/wiki

---

## SQF Language Basics

SQF is Arma 3's scripting language. Key syntax rules for editing these files:

- Statements end with `;`
- Variables are prefixed with `_` for local (`_myVar`) or stored in `missionNamespace` for global
- Functions are called with `[args] call functionName` (synchronous) or `[args] spawn functionName` (new thread)
- `#include "path"` pastes another file's content at compile time
- Comments: `// line comment` or `/* block comment */`
- No tabs — spaces only (the validator flags tab characters)
- Strings use either `"double"` or `'single'` quotes

---

## Validation & Linting

These run automatically on every push/PR via `.github/workflows/testing.yml`. Both Python scripts exit non-zero on error and block CI:

```bash
# SQF syntax validation — checks bracket matching, semicolons, tabs
python3 releaseVerificationAndDeployment/sqf_validator.py

# Config/HPP bracket validation — checks .cpp and .hpp files
python3 releaseVerificationAndDeployment/config_style_checker.py
```

The sqflint job runs alongside these but `continue-on-error: true` — it never blocks CI due to false positives.

Run both Python validators locally before pushing any SQF changes.

---

## Build & Release

```bash
# Standard dev build (interactive — prompts before packing)
python3 releaseVerificationAndDeployment/build.py

# CI/automated build (non-interactive, used by deploy workflow)
python3 releaseVerificationAndDeployment/build.py --deploy

# Build a specific variant (e.g. exemplar mission)
python3 releaseVerificationAndDeployment/build.py --build config_ExemplarMission.json
```

Build config: `releaseVerificationAndDeployment/config.json` defines an explicit `include` allowlist and the output name/version. New repository folders do not ship unless deliberately added. The builder rejects QA/tooling folders and runtime logs before and after archive creation; patch releases use the same allowlist. Output zips land in `release/`. The deploy workflow uploads the main WMP pack, patch, Compositions, Unit Insignias, and the Claude Mission Config Skill. The dormant Exemplar build remains available manually but is not currently produced by `deploy.sh`.

### Claude Mission Config Skill (separate release item)

`.claude/skills/mission-pack-config/` — a Claude Skill (usable with Claude Code, Claude.ai, and as ChatGPT Custom GPT instructions) that guides configuring every WMP feature for a mission. It is **not** included in the main WMP pack build (`config.json` deliberately excludes `.claude`); it ships as two separate release artifacts, since claude.ai's own "Upload skill" dialog needs a different zip shape than a mission-project drop-in does:

- `releaseVerificationAndDeployment/config_claudeSkill.json` (`scriptName: "Claude Mission Config Skill"`, `include: [".claude", "LICENSE"]`) builds `Claude_Mission_Config_Skill-<version>.zip`, which keeps the `.claude/skills/mission-pack-config/` path prefix intact — unzipping it into a mission project drops that folder at the project's root, same layout as this repo, and Claude Code auto-discovers it there.
- `releaseVerificationAndDeployment/package_claude_skill_upload.py` builds `mission-pack-config-<version>.zip` (a plain skill folder at the zip root — `mission-pack-config/SKILL.md`, no `.claude/skills/` prefix), the shape claude.ai's "Upload skill" dialog and the Skills API require. Repacking the mission-project zip does **not** work for this — the extra path prefix makes the uploader unable to find `SKILL.md`.

Both are built in `deploy.sh`. Every push validates `SKILL.md`'s frontmatter against claude.ai's own upload constraints via `releaseVerificationAndDeployment/claude_skill_validator.py` (name ≤64 chars kebab-case, description ≤1024 chars, no angle brackets, only the allowed frontmatter keys, exactly one `SKILL.md`) — run it locally (`pip install pyyaml` first) after editing `SKILL.md`'s frontmatter, since an over-length or malformed description fails silently at upload time otherwise. See the wiki's **Claude Mission Config Skill** page for usage with both Claude and ChatGPT, and `.claude/skills/mission-pack-config/SKILL.md` for the skill's own routing logic and per-feature reference files.

### Full development audit mission

Use the proven PR-review VR mission for feature and release testing. Its builder stages the exact
release allowlist, preserves the loadable legacy `mission.sqm`, and runs the real pack entry points:

```bash
python3 releaseVerificationAndDeployment/build_pr_review_audit.py --destination .qa/staged/WMP_PR_Review_Audit.VR --suite all --mode manual
```

Launch with `launch_pr_review_audit.ps1`. CBA, ACE, ZEN and ACRE2 are required; BattlEye remains
disabled and the window is 2560×1440. Manual mode never starts state-mutating audit cases. The
generated full-range mission is experimental and is not a substitute for this gate. Read
`releaseVerificationAndDeployment/fullArmaAudit/PROCESS.md` before running or changing it.

### Cover / Loading Screen Generation

The cover image `Pictures/loading.jpg` (the in-game `loadScreen`/`overviewPicture` and the README banner) is **generated** — the title and version number are rendered programmatically so the version never goes stale. The version is read from `description.ext`'s `onLoadName` (e.g. `"Mission Pack v4.8.0"`).

```bash
# Regenerate locally (requires Pillow): version parsed from description.ext
pip install -r releaseVerificationAndDeployment/requirements.txt
python3 releaseVerificationAndDeployment/generateLoadingScreen.py
# or render an explicit version:
python3 releaseVerificationAndDeployment/generateLoadingScreen.py 4.8.0
```

`generateLoadingScreen.py` draws onto a text-free base image with the bundled Stardos Stencil font. The generator, base image, font and its OFL license live under `releaseVerificationAndDeployment/loadingAssets/` — which is inside the `releaseVerificationAndDeployment` folder already in every build's `notlist`, so **these dev assets never ship**; only the generated `Pictures/loading.jpg` does (Pictures is included in the main and Exemplar builds, excluded in the Unit Insignias build). Layout constants (font sizes, blue colour, x/y anchors) are at the top of the script.

Two workflows keep it in sync: `.github/workflows/update-cover.yml` regenerates and commits `Pictures/loading.jpg` back to `main` whenever `description.ext` changes; `deploy.sh` regenerates it (from the release tag) before packing so each released zip matches the tag.

**Release ordering guard:** before packing anything, `deploy.sh` fails fast unless the version in `description.ext`'s `onLoadName` matches the release tag (a prerelease suffix like `-rc1` is ignored — only the `X.Y.Z` core is compared). This enforces that the version was bumped on `main` first — which is what triggers `update-cover.yml` to refresh the README/committed cover — so the **visible** cover is already current everywhere before a release is built. The check uses `generateLoadingScreen.py --print-version` (the same parser that renders the cover). Practical workflow: bump `onLoadName` on `main`, let `update-cover.yml` commit the new `Pictures/loading.jpg`, then publish the release; if the tag and `onLoadName` disagree, the release aborts with a message telling you which to fix.

---

## Architecture

### Function Registration

Every callable function is declared in `MissionScripts/WaldosFunctions.sqf` via Arma 3's `CfgFunctions` system. That file is `#include`-d by `description.ext`, which causes Arma 3 to preload all functions at mission start.

**Naming rule:** all functions are `Waldo_fnc_FunctionName` (CamelCase suffix). The class name in `WaldosFunctions.sqf` must match the suffix exactly. Adding a new function requires two steps: (1) create the `.sqf` file, (2) add the class entry to `WaldosFunctions.sqf`.

### Mission Execution Flow

```
Mission load
  └─ description.ext          → #includes WaldosFunctions.sqf (registers all Waldo_fnc_*)
        │                       #includes GarageDisplayDefine.hpp (VVD GUI)
        │                       #includes mission.sqm (for loadout system)
        │
        ├─ initServer.sqf       (server only)
        │     ├─ Sets supply/medical box classnames in missionNamespace
        │     ├─ Sets paradrop altitude/speed/chute variables
        │     └─ [] call Waldo_fnc_SideBaseLoadoutSetup
        │           └─ Scans mission.sqm for all playable unit loadouts per side
        │               Stores as Logi_MissionSQMArray_West/East/Ind/Civ
        │
        ├─ init.sqf             (all clients + server, on loading screen transition)
        │     ├─ [] call Waldo_fnc_ZenInitModules     (Zeus Enhanced custom modules)
        │     ├─ "DAY"/"NIGHT" call Waldo_fnc_AITweak (AI skill adjustment)
        │     ├─ [_RadioSetups] call Waldo_fnc_ACRE2Init (radio channel assignment)
        │     ├─ call Waldo_fnc_InitVehicles           (vehicle action setup)
        │     ├─ call Waldo_fnc_AddDocs                (briefing documents)
        │     ├─ call Waldo_fnc_SetTeamColour          (squad colour by role)
        │     ├─ ["",""] call Waldo_fnc_InfoText        (intro title screen)
        │     └─ Sets WALDO_INIT_COMPLETE flag
        │
        └─ initPlayerLocal.sqf  (per-player, on each join/respawn)
              ├─ Saves starting loadout via BIS_fnc_saveInventory
              ├─ Adds "Flip Vehicle" action
              └─ CBA Respawn event → restores saved loadout + re-adds flip action
```

### Key Global Variables (missionNamespace)

| Variable | Set in | Purpose |
|---|---|---|
| `WALDO_INIT_COMPLETE` | `init.sqf` | Signals client init is done; scripts should `waitUntil` on this |
| `Logi_MissionSQMArray_West/East/Ind/Civ` | `initServer.sqf` | Unique loadout arrays scraped from mission.sqm |
| `Logi_SupplyBoxClass` / `Logi_MedicalBoxClass` | `initServer.sqf` | Classnames of spawnable crates |
| `WALDO_STATIC_MINALTITUDE` etc. | `initServer.sqf` | Paradrop altitude/speed thresholds |
| `Waldo_Player_Inventory` | `initPlayerLocal.sqf` | Per-player saved loadout |
| `Waldo_ACRE2Setup_LRChannels_BLUFOR` etc. | `init.sqf` | ACRE2 channel name arrays per side |

---

## Feature Configuration Guide

This section covers the systems mission makers configure. All configuration lives in the init files — not in the script files themselves.

### Loadout & Logistics System (Critical)

The supply/logistics system is driven entirely by playable unit loadouts in `mission.sqm`:

- `initServer.sqf` scans all playable units via `Waldo_fnc_SideBaseLoadoutSetup`, extracts weapons/ammo/clothing/items, deduplicates, and stores globally
- These arrays power supply crate contents, limited ACE arsenals, and Zeus logistics modules
- **IMPORTANT:** Unit loadouts **must** be edited using ACE Arsenal in the Eden Editor — vanilla default loadouts produce empty/incomplete crates
- **IMPORTANT:** Mission binarization must be **disabled** (right-click mission in editor → Properties → uncheck Binarize) for `mission.sqm` to be readable

Custom crate classnames (in `initServer.sqf`):
```sqf
missionNamespace setVariable ["Logi_SupplyBoxClass", "B_supplyCrate_F", true];
missionNamespace setVariable ["Logi_MedicalBoxClass", "ACE_medicalSupplyCrate_advanced", true];
```

### AI Rebalance (`init.sqf`)

```sqf
Waldo_AIRebalance_Enable = true;
Waldo_AIRebalance_Profile = "LEGACY"; // LEGACY | PUBLIC | STANDARD | VETERAN
["DAY", Waldo_AIRebalance_Profile] call Waldo_fnc_AITweak;
```

The compatibility profile preserves established missions. New missions can select a lower-lethality or balanced profile and layer mission-defined faction and role hash-map overrides. NIGHT mode reduces unaided spotting more strongly than NVG-assisted spotting. Locality-aware CBA handlers cover editor, scripted and Zeus-spawned AI, including headless clients.

### Optional Feature Systems (`init.sqf`, `initPlayerLocal.sqf`, `initServer.sqf`)

Shared configuration belongs in `init.sqf`, player presentation/actions in `initPlayerLocal.sqf`, and server-only limits, asset pools and authority startup in `initServer.sqf`; configuration never belongs inside implementation scripts. Guard defaults with `isNil` so a JIP machine does not overwrite state published after a mid-mission ZEN change. Persistence requires a detected INIDBI2 runtime and keeps database access on the server. Object scaling is callable and server-validated without a background initializer. Dynamic AA resolves assets through its own server-side side/faction pools; do not replace these independent contracts with a shared profile framework. AI rebalance and breaching are all-machine initialisers because AI ownership and detonation-event locality can move across server, client and headless-client machines.

The same systems can be configured during play under **Waldos Mission Modules**. ZEN requests pass through `Waldo_fnc_FeatureRuntimeApply`, which accepts assigned curators only, publishes configuration, sends an ordered live-setting payload before locality-appropriate initializers, and retains JIP initialization where required. Joining clients and headless clients request an ordered server snapshot before activating locality-sensitive features; do not replace that handshake with assumptions about public-variable delivery order. Hazard and breaching dialogs can export equivalent setup calls for permanent mission configuration.

Dynamic AA is configured through `Waldo_fnc_DynamicAACreate` or the **Dynamic AA - Create** ZEN module. Every system requires a unique ID and owns its radar, response groups, markers and detector handle so it can be replaced or cleaned independently. The **Dynamic AA Example** composition anchors one system to a placed object for editor-time setup. Component placement rejects any candidate steeper than `Waldo_DynamicAA_MaxSlopeDegrees` (default 12°, `MissionConfig\airOperationsConfig.sqf`) the same way it rejects a nearby tree or building, so the ring search keeps walking outward toward a flatter shelf instead of leaving a radar or launcher visibly tilted on a hillside; the whole creation is rejected with a clear ZEN error if no component finds a flat, clutter-free spot within the search radius. Per-component clearance is derived from `sizeOf` (a map-icon-oriented size estimate, not true physical geometry - the only size query available before an object is actually spawned) scaled and capped conservatively rather than generously, and the object-blocker check ignores units/curator logic objects rather than treating anything nearby as an obstruction; both existed specifically because a large map-icon size on a class like `Land_Radar_F` combined with an unfiltered "any nearby object blocks" check could reject placement across an entire large search even on genuinely open, non-manicured terrain.

Airborne Gunship Support uses the same named-instance principle but a separate feature-specific state machine. `Waldo_fnc_GunshipRegister` accepts existing or pooled/spawned aircraft, explicit turret profiles and service policy. Aircraft lifecycle and permissions remain server-owned; map selection, local markers, notifications and approved remote-control handoff run on clients. Do not assume turret paths are portable between aircraft mods. The **Gunship Support Example** composition registers a placed, crewed VTOL for editor-time setup, orbiting a movable marker.

Dynamic AO (`Waldo_fnc_DynamicAOCreate`, the **Dynamic AO - Create** ZEN module) builds a complete
randomized area of operations — infantry patrols, building garrisons, static weapons, weighted
vehicle/air patrols, civilians, parked cars, minefields and manned roadblocks, each independently
optional — from one HashMap config. Generated AI use the active WMP AI profile. Reusing an `id`
replaces the previous AO safely; the invisible centre anchor and per-minefield anchors are
curator-editable deletion handles. See `wiki/Dynamic-AO-Generation.md` for every supported config key.
The **Dynamic AO Example** composition anchors one AO to a placed object for editor-time setup.

### ACRE2 Radio Setup (`init.sqf`)

```sqf
private _RadioSetups = [
    ["Viking-1-1", [1,5]],   // [group name, [LR channel numbers]]
    ["Viking 5",   [2,7]],
    ["Banshee",    [4,1]]
];
[_RadioSetups] call Waldo_fnc_ACRE2Init;
```

Group names must match exactly what is set in Eden Editor. Channel numbers reference the position in the `Waldo_ACRE2Setup_LRChannels_BLUFOR/OPFOR/IND/CIV` arrays (1-indexed). AN/PRC-343 short-range radios are assigned automatically based on squad numerical designations. CEOI auto-populates in the map screen.

### Paradrop Configuration (`MissionConfig\airOperationsConfig.sqf`)

Most "Plane"-class assets automatically get HALO/static-line actions. Override the shared envelope in `MissionConfig\airOperationsConfig.sqf` (published as `true`/broadcast SERVER entries — do not paste these as raw `setVariable` calls into an init file, the loader owns them):

```sqf
["WALDO_STATIC_MINALTITUDE", 180],  // metres
["WALDO_STATIC_MAXALTITUDE", 350],
["WALDO_STATIC_MAXSPEED", 310],     // km/h
["WALDO_STATIC_STATICCHUTE", "NonSteerable_Parachute_F"], // vanilla; e.g. "rhs_d6_Parachute" if the mission runs RHS
["WALDO_PARA_HALOALTITUDE", 1000],
["WALDO_PARA_HALOCHUTE", "B_Parachute"]
```

For custom aircraft that don't auto-detect, add in the object's init field in Eden Editor:
```sqf
[this] call Waldo_fnc_VehicleJumpSetup;
```
This only adds the jump action — it does not fly the plane anywhere.

#### Reliable AI flight — quick setup (`Waldo_fnc_ParadropQuickFlightSetup`)

For a mission maker's own placed-and-crewed aircraft, one call from the object's init field gives it
a reliable AI-flown route (standby → green line → red line → exit, looping by default) toward a
drop point, plus the configured jump action — without the full Dynamic Drop Zone registry below:

```sqf
[this, "dz1"] call Waldo_fnc_ParadropQuickFlightSetup;
// [aircraft, target(marker name/position/object), direction(-1 = auto), altitude, maxSpeed, options]
```

`target` as a marker name is the beginner-friendly option: place a named marker in Eden and
reference it here, no coordinate math needed. A marker that was never placed or is misnamed is
reported in-game via `systemChat`, not just the RPT log.

It clears the aircraft's existing waypoints before adding the generated route — leftover Eden
waypoints fighting a scripted route is the single most common reason a hand-wired paradrop plane
was unreliable. If the pilot's group has other units besides this aircraft's crew, the crew is
automatically isolated into a dedicated fresh group first so those other units never lose their own
waypoints. Waits (bounded, 30s) for a pilot if the aircraft's crew hasn't spawned in yet, so it
is safe to call from an object's own init field even when another init field (e.g.
`Waldo_fnc_MoveInCargoPlane`) assigns that pilot. Before installing the jump action, the requested
static-line/HALO envelope is run through `Waldo_fnc_ParadropNormalizeJumpEnvelope`, using the same
clamped altitude/speed `Waldo_fnc_ParadropBuildFlightRoute` actually flew (not the raw input) —
a jump action gated on altitude/speed thresholds the plane's own route can never satisfy is the
concrete "jump action never becomes available" failure this closes; `ParadropCreateDropZone` below
normalizes off the same route-returned basis. `createMarkers` defaults to `true`
(AREA/STANDBY/GREEN/RED/POINT markers, same layout as `ParadropCreateDropZone`) so a mission maker
sees a working drop zone immediately — pass `false` for a map-clutter-free operation. AREA/STANDBY/
GREEN/RED are created invisible (alpha 0 — still real, queryable markers at the exact route
positions) so only the single named POINT marker at the drop point is actually shown on the map,
instead of the previous five-marker stack. Markers are
removed automatically on aircraft death/deletion or once a `DESPAWN` lifecycle run reaches its exit
point; set `keepMarkersOnCleanup` to `true` to opt out and leave them on the map instead. Neither
this nor the opt-out ever deletes the aircraft or its crew, since this entry point never owns their
lifecycle (unlike `ParadropCreateDropZone`, whose `DESPAWN` does delete the aircraft it spawned). See
the script header for the full `options` HashMap (jump envelope overrides, `lifecycle`
LOOP/RETAIN/DESPAWN, `circuitDirection`, `createMarkers`, `keepMarkersOnCleanup`, `name`).

The exact same route logic (`Waldo_fnc_ParadropBuildFlightRoute`) powers the fuller **Dynamic Drop
Zone Operations** system (`Waldo_fnc_ParadropCreateDropZone`, the ZEN "Dynamic Paradrop" module) —
which additionally spawns/crews the aircraft itself, manages a named registry, optional generated
jumpers, auto-drop-on-approach and map markers. Use the ZEN module or `ParadropCreateDropZone` for a
managed multi-use operation; use `ParadropQuickFlightSetup` for a mission maker's own placed plane.

### Radio Jamming — ACRE2 / TFAR (`init.sqf`)

Localised, area-denial radio jamming for **both** ACRE2 and TFAR. A *jammer* is any world object with a radius; radios inside its field lose comms, with a linear falloff at the edge. Enabled by default (`Waldo_Jamming_Enable = true` in `init.sqf`) but has **zero effect until a jammer is placed** — the radio engines pass ACRE2/TFAR through unchanged when the registry is empty.

**Server-authoritative registry, client-local engines.** The jammer registry (`Waldo_Jamming_Registry`) is owned and broadcast by the server via the create/toggle/remove functions (which forward to the server when called on a client, exactly like `Waldo_fnc_SafeStart`). Each client installs the radio engines from `init.sqf` (JIP-safe): the ACRE2 custom signal function and/or the TFAR throttle loop, plus an on-screen "radio jammed" watcher.

Placing jammers (any of these):
```sqf
// From an object's init field in Eden:
[this] call Waldo_fnc_Jammer;                         // 300 m, jams everyone, all bands
[this, 500, "EAST"] call Waldo_fnc_Jammer;            // 500 m, jams OPFOR only
// From a trigger / script (full params):
[myTower, 800, "ALL", [[30, 88]], 50, 1, true, true, [90, 60], [4, 2], true] call Waldo_fnc_Jammer;
// params: [object, radius, affectedSides, bands, falloff, strength, active, createMarker, sector, duty, jamUAV]
```
`affectedSides`: `"ALL"`, a side, or an array — accepts sides or strings (`"WEST"/"BLUFOR"`, `"EAST"/"OPFOR"`, `"IND"/"INDFOR"`, `"CIV"/"CIVILIAN"`). `bands`: `"ALL"` or an array of `[minMHz, maxMHz]` ranges (**ACRE2 only** — TFAR jamming is always broadband). `sector`: `[]` for omni or `[bearing, arc]` for a directional cone. `duty`: `[]` for constant or `[onSec, offSec]` to pulse. `jamUAV`: also jam drones in the field. `Waldo_fnc_Jammer` returns a numeric jammer id.

**UAV / UGV jamming** (`jamUAV = true`): drones inside the field are jammed too. The server freezes autonomous drone AI (`Waldo_fnc_JammingUavServer`). A controlling player's client (`Waldo_fnc_JammingUavClient`) degrades the video feed as the link weakens and severs the terminal link at near-total jamming. A persistent `UAV LINK DEGRADED` panel (IDC 5311) shows signal-loss guidance, followed by a separate datalink-loss notice when the terminal disconnects.

**Jamming model** (global toggles in `init.sqf`, read by `Waldo_fnc_JammingFactor`):

| Flag | Default | Effect |
|---|---|---|
| `Waldo_Jamming_LOS` | `true` | Terrain/hills between jammer and radio block the field (`terrainIntersectASL`). |
| `Waldo_Jamming_BurnThrough` | `true` | Higher-power radios resist jamming — the effective radius shrinks by `(power/ref)^0.35`. |
| `Waldo_Jamming_BurnThroughRef` | `500` | Reference radio power (mW); a radio at this power is fully affected. |
| `Waldo_Jamming_Curve` | `"LINEAR"` | Edge falloff shape: `"LINEAR"` or `"INVSQ"`. |
| `Waldo_Jamming_Destructible` | `true` | Destroying a jammer's object auto-deregisters it (EW objectives for free). |
| `Waldo_Jamming_GmOverlay` | `false` | Optional curator-only Draw3D marker/facing-line over each jammer. |
| `Waldo_Jamming_ScanRange` | `3000` | Detection range (m) of the handheld RDF ACE self-action. |

**EW toolkit (players):** every jammer object gets ACE actions **Toggle Radio Jammer** (anyone) and **Disable Radio Jammer** (engineers — destroys it); every player gets an ACE self-action **Scan for Radio Jammers** (`Waldo_fnc_JammerScan`) that reports bearing / coarse range / strength to the nearest active emitter for RDF hunting.

**Feedback:** while jammed, the player sees a persistent `ELECTRONIC WARFARE` panel on the main display (IDC 5310, `Waldo_fnc_JammingHud`). It names the condition as `RADIO INTERFERENCE`, shows signal loss as a percentage and bar, and displays `LINK QUALITY DEGRADED`. Entry, restoration, scan, and UAV-link changes use timed notices rather than game-chat logging.

Managing jammers later (server-authoritative; `ref` = the jammer object or its id):
```sqf
[myTower, false] call Waldo_fnc_JammerToggle;   // switch off (omit the bool to flip)
[myTower, true]  call Waldo_fnc_JammerRemove;   // remove + delete the object
```

Global flags (`init.sqf`):
```sqf
Waldo_Jamming_Enable = true;                                          // false = feature off entirely
missionNamespace setVariable ["Waldo_Jamming_Notify", true, true];    // on-screen "radio jammed" prompt
```

**ACRE2 requirement:** the ACRE2 signal model must be **LOS Multipath** (the default) or **Arcade** — ACRE2 does not call the custom signal hook under *LOS Simple*. The jamming model is receiver-oriented and symmetric: a link is degraded when **either** endpoint (the receiving or transmitting radio) sits inside an active field affecting the local player's side and matching the band. Implemented in `MissionScripts/MissionInit/Jamming/` (`Waldo_fnc_JammingInit`, `Waldo_fnc_Jammer`, `Waldo_fnc_JammerToggle`, `Waldo_fnc_JammerRemove`, `Waldo_fnc_JammingFactor`, `Waldo_fnc_JammingAcreSignal`, `Waldo_fnc_JammingTfarLoop`, `Waldo_fnc_JammingUavServer`, `Waldo_fnc_JammingUavClient`, `Waldo_fnc_JammerInteraction`, `Waldo_fnc_JammerScan`, `Waldo_fnc_JammerMapDraw`, `Waldo_fnc_JammingHud`).

Zeus ("Waldos Mission Modules"): **Jammer: Place New Emitter** (dialog: radius / falloff / strength / affected side / frequency bands / initial state / cone arc + bearing / pulse timings / jam UAVs / map marker / per-emitter curator 3D marker / emitter class), **Jammer: Toggle Nearest Emitter**, **Jammer: Delete Nearest Emitter**. The script API's argument 11 is the per-emitter curator overlay; `Waldo_Jamming_GmOverlay` remains the global show-all override.

### EMP Burst (`Waldo_fnc_EMP`)

A one-shot electromagnetic pulse — an area electronics kill, the offensive counterpart to the (persistent) jammer. Server-authoritative; because it fires once and reverts on a timer it runs **no polling loops**, so it is free to leave available.

```sqf
[getPosATL myObject, 200, 30] call Waldo_fnc_EMP;   // [position, radius(m), duration(s)]
[commandVehicle] call Waldo_fnc_EMPImmune;          // exempt a unit/vehicle (occupants inherit)
```
Effects in radius (non-immune): infantry lose NVGs and (TFAR) radio use for the duration; vehicles have their engine cut (fuel drained, restored after); every affected **player** gets a white-out flash. Set `Waldo_EMP_NotifyAffectedPlayers = true` to add an explicit local disruption notice; it defaults off. Applied per-entity on its owning machine via `Waldo_fnc_EMPApply`. Zeus: **EMP Detonation** (dialog: radius / duration). Module parameters are written to RPT, not chat. Implemented in `MissionScripts/MissionInit/ElectronicWarfare/`.

### Signal Trackers — C-Track (`Waldo_fnc_Tracker`)

Plant a tracker on a unit or vehicle and a chosen side follows it live on the map — electronic recon. Server-authoritative registry (`Waldo_Tracker_Registry`, JIP-safe) with a light server prune loop that drops trackers whose target dies; markers are drawn **locally** on each tracking client (`Waldo_fnc_TrackerRender`) so they stay hidden from the tracked side.

```sqf
[enemyTruck, west, "Convoy Lead"] call Waldo_fnc_Tracker;   // [target, trackingSide, label]
[cursorTarget] call Waldo_fnc_TrackerAttach;                // plant on what you're looking at (your side)
[enemyTruck] call Waldo_fnc_TrackerRemove;                  // remove
```
Players get an ACE **Plant Signal Tracker** action on units and vehicles; Zeus gets a **Plant Signal Tracker** module (attaches to the nearest unit, tracked by a chosen side). Implemented in `MissionScripts/MissionInit/ElectronicWarfare/`.

### Hazardous Environments (`Waldo_fnc_HazardRegisterZone` / `Waldo_fnc_HazardRegisterPresetZone` / `Waldo_fnc_HazardRegisterEmitter`)

Fixed-area or moving hazard zones (radiation is the shipped preset family) with real exposure/damage, protection (vehicle/indoor/equipment), a continuous per-player HUD, Geiger/cough audio, and entry/exit/damage-stage notifications. Profiles are hashmaps a mission can extend without changing the API:

```sqf
["reactor", reactorTrigger, "SEVERE_RADIATION"] call Waldo_fnc_HazardRegisterPresetZone;   // preset + area
["leaking_truck", truck1, 8, _profile] call Waldo_fnc_HazardRegisterEmitter;               // moving source, radius
["reactor"] call Waldo_fnc_HazardUnregisterZone;                                            // remove
```

Set `["markerEnabled", true]` in a profile to tie a broadcast `Waldo_fnc_Create3DMarker` world marker to the zone's own area — for an object/emitter area this anchors directly to the source object, so the marker tracks a moving vehicle live and every player (not just whoever is currently exposed) can see where the hazard is. Optional `["marker", HASHMAP]` supplies `Waldo_fnc_Create3DMarker` options (icon/colour/text/offset/distance/sides); unset keys default to a warning icon, the profile's `label`, and a 200 m view distance. The marker is created once at registration and torn down automatically wherever the zone is unregistered — it plays no part in the per-tick evaluation loop.

`insideBuilding` (used only when a profile sets `protectIndoors: true`, true for every shipped radiation preset) is a documented-expensive engine query; `Waldo_fnc_HazardTick` throttles it to once per `Waldo_Hazard_IndoorCacheSeconds` (default 3) per zone via `Waldo_fnc_HazardProtectionFactor`'s optional cache-key argument, instead of re-testing it on every tick a player stands inside a zone.

See `wiki/Optional-Feature-Systems.md#hazardous-environments` for the full preset catalogue, protection/awareness options and the Radiation Hazard / Hazard Emitter Moving compositions.

### MHQ / Mobile Command Post (Eden Editor)

1. Place a vehicle (or static object) with a variable name, e.g. `MHQ_1`
2. Place a Game Logic near it
3. Place tent/crate objects you want deployed — **sync each one to the Logic** (not the vehicle)
4. Raise ground-placed objects ~1ft if using a vehicle (accounts for suspension settling)
5. In the vehicle's init field:
```sqf
[this] call Waldo_fnc_MHQSetup;
// or with options:
[this, true, true, 180, 4] call Waldo_fnc_MHQSetup;
// params: [vehicle, modernAudio, enableLogistics, logiBearing, logiDistance]
```
Players get ACE3 "Deploy/Tear Down Command Post" actions. Deployed state creates a named respawn point and map marker.

### Respawn Options (`initPlayerLocal.sqf`)

Two optional behaviours are commented out by default — uncomment to enable:

```sqf
// Save loadout when closing ACE Arsenal (respawn with chosen kit):
["ace_arsenal_displayClosed", {
    [player, [missionNamespace, "Waldo_Player_Inventory"]] call BIS_fnc_saveInventory;
}] call CBA_fnc_addEventHandler;

// Respawn with what you died with (instead of starting kit):
["CAManBase", "Killed", {
    params ["_unit"];
    if (_unit == player) then {
        [_unit, [player, "Waldo_Player_Inventory"]] call BIS_fnc_saveInventory;
    };
}] call CBA_fnc_addClassEventHandler;
```

### ENDEX / Mission End

```sqf
[] spawn Waldo_fnc_ENDEX;
```

Freezes the mission: broadcasts "ENDEX ENDEX ENDEX", locks all weapons (ACE safety mode), heals all players, deletes fired rounds, sets all AI to CARELESS/BLUE, makes all players invincible. Also accessible via the Zeus Enhanced "Call Endex" module.

The ENDEX hint also shows an **After-Action Report** when AAR tracking is running. Tracking is started automatically from `initServer.sqf` via `[] call Waldo_fnc_AARTrack`, which registers a single `EntityKilled` mission event handler (fires on all machines, so server-side registration captures every kill). If `Waldo_AAR_StartTime` is unset the ENDEX simply omits the AAR block.

ENDEX and the AAR are one player-facing flow, not separate actions. Set
`Waldo_ENDEX_ReportDuration` to control how long the combined mission-end report
remains visible (default 45 seconds).

The AAR reports: mission **duration**, **KIA** per side, **player losses**, **vehicles lost** per side, **WIA** per side, **friendly-fire** incidents, an **objective summary**, and a **top-fraggers** leaderboard. Each extra line is omitted when its tally is empty. Details:
- *Vehicle losses / friendly fire / fraggers* come from the same `EntityKilled` handler, which now also reads `_killer`/`_instigator`: a kill where instigator and victim share a side counts as friendly fire; an enemy kill by a human player feeds the leaderboard (`Waldo_AAR_Frags`).
- *WIA* requires **ACE medical**. An `ace_unconscious` listener registered in `init.sqf` (runs on all machines) forwards each unit's first unconsciousness to the server via `Waldo_fnc_AARWound`, so each wounded unit is counted once.
- *Objective summary* is populated automatically when objectives are created with `Waldo_fnc_CreateObjective` / resolved with `Waldo_fnc_SetObjectiveState` (they maintain the broadcast `Waldo_AAR_Tasks` ledger).

For a custom end screen, configure `CfgDebriefing` → `End1` in `description.ext`, then trigger with `[[], "End1"] call BIS_fnc_endMission;`.

### WMP UI notifications and recovery

Mission makers can use the pack's padded, safe-zone-aware notification card directly:

```sqf
["OBJECTIVE UPDATED", "Secure the relay station.", "INFO", 10, "TOP", "OBJECTIVE", "JOINT OPERATIONS"]
    call Waldo_fnc_ShowUiNotification;
```

Arguments are `[title, message, state, duration, placement, channel, source]`. States are `INFO`, `SUCCESS`, `WARNING`, or `ERROR`; duration `0` is persistent. A screen placement has one owner, so newer cards replace rather than overlap. The API is client-local and safe on dedicated servers. `[] call Waldo_fnc_ClearUiPanels` performs repeat-safe local recovery of WMP-owned overlays and displays only.

Players receive **WMP Interface > Clear Stuck WMP UI** as an ACE self-interaction. Vanilla `addAction` is installed only when ACE interaction is unavailable. Setup runs on JIP and respawn and has no authority scheduler or public state.

### Zeus-authored notification broadcasts (`Waldo_fnc_NotificationBroadcast`)

Sends a WMP notification card to a chosen audience instead of a single local player. Server-authoritative — self-forwards to the server when called from a client, same as `Waldo_fnc_Jammer`.

```sqf
[createHashMapFromArray [
    ["title", "FALL BACK"], ["message", "Regroup at the rally point."], ["state", "WARNING"],
    ["duration", 10], ["placement", "TOP"], ["audience", "SIDE"], ["side", west]
]] call Waldo_fnc_NotificationBroadcast;
```

Config keys: `title`, `message`, `state` (`INFO`/`SUCCESS`/`WARNING`/`ERROR`), `duration`, `placement`, `channel`, `source` (same meaning as `Waldo_fnc_ShowUiNotification`'s arguments), plus `audience` — `ALL` (default), `SIDE` (reads `side`), `GROUP` (reads `group`, matched case-insensitively against `groupId`), or `UNITS` (reads an explicit `units` array of player objects). Returns the number of distinct players actually reached.

Zeus ("Waldos Mission Modules"): **Mission Flow: Send Notification** — a dialog for title/message, type, duration, placement, and audience (All / By Side / By Group / Selected Unit(s)), routed through the curator-authenticated `Waldo_fnc_ZenNotifyServer` bridge before calling the same public function.

### Safestart (optional)

Freezes all players at mission start — the reversible mirror of ENDEX. While active: weapons are safe and every shot/grenade/launcher/vehicle-weapon round is deleted, players take and deal **no damage**, players are **confined to a safe zone**, and an on-screen **banner** (with a live go-live countdown when a timer is running) is shown. JIP and respawning players are re-frozen automatically.

Auto-starts from `initServer.sqf` (set the flag to false to start the mission live):
```sqf
missionNamespace setVariable ["Waldo_SafeStart_Confine", true, true];   // safe-zone confinement on/off
missionNamespace setVariable ["Waldo_SafeStart_Radius", 75, true];      // per-player radius (metres)
missionNamespace setVariable ["Waldo_SafeStart_ZoneMarker", "", true];  // marker name for one shared zone (else per-player anchor)
missionNamespace setVariable ["Waldo_SafeStart_AutoStart", true, true]; // false = no safestart at start
```

Scripting API (server-authoritative — safe to call from a client, it forwards to the server):
```sqf
[true]  call Waldo_fnc_SafeStart;        // activate
[false] call Waldo_fnc_SafeStart;        // go live (admin overrule; also cancels any countdown)
[300]   call Waldo_fnc_SafeStartTimer;   // go live automatically in 300s (banner shows the clock)
```

SafeStart and ENDEX keep separate authoritative state and handler ownership. A SafeStart lift never removes an active ENDEX freeze. For controlled rehearsals or QA, `[] call Waldo_fnc_ENDEXReset` removes ENDEX-owned handlers without lifting an active SafeStart.

Zeus ("Waldos Mission Modules"): **Safestart - Activate**, **Safestart - Go Live (Lift)**, and **Safestart - Start Go-Live Countdown** (configured in seconds; displayed to players as `MM:SS`). The countdown can be overruled at any time with the Lift module. Implemented in `MissionScripts/MissionFlowAndUi/safeStart.sqf`, `safeStartTimer.sqf`, `safeStartApply.sqf`.

The active banner always states whether a timer is running. Manual and timed
go-live notices explain which protections were removed and remain visible for
`Waldo_SafeStart_GoLiveHintDuration` seconds (default 12).

### Mission Diagnostics (optional)

Runs a read-only server and client health check at mission start after the loadout scan. Every RPT entry uses the same searchable frame: `[WMP DIAG][run=...][node=SERVER|CLIENT:<owner>][area=...][feature=...][level=...][event=...]`. A hosted server also shows warnings through `systemChat`.

```sqf
// In initServer.sqf. Set false to silence startup diagnostics in a released mission.
missionNamespace setVariable ["Waldo_RunDiagnostics", true, true];
```

Checks distinguish `LOADED`, `ACTIVE`, `DISABLED`, `UNCONFIGURED`, `UNAVAILABLE`, and `ERROR`. Coverage includes representative public APIs, mod dependencies, loadouts, configured classes, mission flow, MHQ, VVD, electronic warfare, party games, interaction equipment, Economy, Zeus registration, local HUD state, 3D markers, and ACE versus vanilla actions. The latest report is broadcast in `Waldo_Diagnostics_LastReport` as `[warningCount, finishedAt, serverChecks, clientReports, runId]`. See `wiki/Mission-Diagnostics.md` for row contracts and filtering examples.

### Persistence (optional, `MissionConfig\persistenceConfig.sqf`)

Optional INIDBI2-backed save/restore for player state and specific registered world objects. Off by default (`Waldo_Persistence_Enable = false`); the server also independently probes for a real, loaded INIDBI2 extension (not just a `CfgPatches` entry) and disables itself cleanly if the probe fails. Database access is server-only; clients only capture/apply their own state.

```sqf
// MissionConfig\persistenceConfig.sqf
["Waldo_Persistence_Enable", false],        // requires a working server INIDBI2 extension
["Waldo_Persistence_SaveLoadout", true],    // filtered inventory (unique ACRE IDs stripped)
["Waldo_Persistence_SaveMedical", true],    // ACE medical state
["Waldo_Persistence_SaveFoodWater", false],
["Waldo_Persistence_SavePosition", false],  // off by default - can bypass mission flow
["Waldo_Persistence_SaveRadios", false],    // per-player ACRE state
["Waldo_Persistence_Scope", "MISSION"]      // MISSION isolates by mission+terrain; CAMPAIGN shares by database name
```

Player state saves/restores automatically once active (`initServer.sqf` starts the server branch, `initPlayerLocal.sqf` starts client capture). World objects must be registered explicitly — `Waldo_fnc_PersistenceRegisterObject` is safe to call directly from an object's own Eden init field with **no `isServer` wrapper**: it silently no-ops on every non-server machine, and the server's own execution of that same init line is what actually registers it, exactly like `Waldo_fnc_Jammer`. Registrations made before the database finishes starting are queued and replayed automatically.

```sqf
[this, "base_supply_1", [true, false, false, false, false]] call Waldo_fnc_PersistenceRegisterObject;
// options: [save cargo, save damage, save fuel, save ammo/pylons, save position]
```

The **Persistence Object Example** composition demonstrates this pattern. Zeus ("Waldos Mission Modules"): **Persistence - Control** (start/reconfigure/stop), **Persistence - Register Object** (assign a stable key/fields to the nearest object during play), **Persistence - Save Now** (immediate capture without stopping the system). See `wiki/Optional-Feature-Systems.md#persistence`.

### Performance regression audit

`releaseVerificationAndDeployment/performance_audit.py` is a comment/string-aware static guard for recurring SQF work. CI rejects new or expanded high-severity world scans, recurring broadcasts/remote execution and unbounded schedulers unless `performance_baseline.json` contains a path/function-specific reviewed reason. Run the scanner and its unit tests before changing persistent loops:

```text
python3 releaseVerificationAndDeployment/performance_audit.py
python3 -m unittest discover -s releaseVerificationAndDeployment -p "test_performance_audit.py" -v
```

Do not regenerate the baseline to bypass review. State static reductions as scan/dispatch/redraw opportunities, never as FPS or bandwidth gains without an Arma runtime capture. First-party fixes must preserve locality, JIP and public mission-maker contracts; optional bundled scripts are reported separately.

### Tasks / Objectives (scripting helper)

A thin, JIP-safe wrapper over the BIS task framework for mission makers who drive objectives from SQF/triggers (the Eden and Zeus task modules remain the GUI option). Server-authoritative — calling on a client forwards to the server automatically.

```sqf
// Create an assigned task with a persistent map marker at the destination:
["secure_lz", west, "Secure the LZ", "Clear and hold the landing zone.", getMarkerPos "lz1"]
    call Waldo_fnc_CreateObjective;

// Later, resolve it (also removes the helper-created marker):
["secure_lz", "SUCCEEDED"] call Waldo_fnc_SetObjectiveState;
```

Params for `Waldo_fnc_CreateObjective`: `[taskId, owner, title, description, destination, state, createMarker, taskType]`. See the script headers in `MissionScripts/MissionFlowAndUi/createObjective.sqf` and `setObjectiveState.sqf`.

### Virtual Vehicle Depot (VVD) — WIP

```sqf
[spawnerObject, helipad, types, allowedSides, sideCheck, removeUavs, range, script]
    call Waldo_fnc_VVDInit;
// types: ["Auto"], ["Ground"], ["All"] or specific type strings
// allowedSides: ["ALL"], ["BLUFOR"], ["OPFOR"], ["INDEP"], ["CIV"]
```

This feature is explicitly marked **WIP and not recommended for live missions**. Vehicle removal routes deletion to the vehicle's owning machine via `Waldo_fnc_VVDPurgeVehicle` — depot vehicles and their (UAV) crew are created with `createVehicle`/`createVehicleCrew` on whichever client pressed spawn, so a client-side `deleteVehicle`/`deleteVehicleCrew` issued from another machine silently no-ops on the remote object; owner-routing fixes that dominant cause of orphaned UAV crew. A UAV with a player actively connected via a terminal remains an engine edge case with no guaranteed teardown. For a fully stable vehicle-spawning experience use **ACE Garage** instead. If you do use VVD, test thoroughly with your exact mod set first.

### Zeus Enhanced Modules

All 15 core and 19 Economy modules are listed in `releaseVerificationAndDeployment/zeus_script_parity.json`. `zeus_script_parity_checker.py` verifies their registrations, handlers, declared public APIs and required parity controls. A static pass establishes wiring, not in-engine usability; runtime Zeus placement, locality and dialog acceptance must still be recorded through the full Arma audit mission. See `wiki/Zeus-And-Script-API-Parity.md`.

```sqf
[] call Waldo_fnc_ZenInitModules; // already called for interface clients in initPlayerLocal.sqf
```

Registers "Waldos Mission Modules" in the Zeus module menu: Player Supply Crate, Field Hospital Crate, Call Endex, Custom Mission End, Fortify Budget Manager, Spawn AI Convoy. Silently does nothing if Zeus Enhanced is not loaded.

### Waldos Economy Systems (Resource / Research / Build / Buy + Ground Command)

A self-contained, **pub-Zeus** RTS-style economy suite. It exposes every action as a **Zeus
Enhanced custom module** under the **"Waldos Economy Systems"** category (registered by
`Waldo_fnc_EcoCore_registerZenModules`), so it works for any curator including player-controlled
Zeus, with no editor work required. **Zeus Enhanced is required for the Zeus authoring menu** —
without ZEN the suite still runs server-side (income, research, production, request handling) but
exposes no in-Zeus menu. The four systems:

- **Resource** — define arbitrary resources (name/colour/icon/storage cap), spawn collectable
  resource crates, and create capturable zones that passively generate resources (with deposit
  caps). Per-side storage limits apply.
- **Research** — a Research Center where a side spends resources on custom research with costs,
  prerequisites and mutual exclusivity.
- **Build** — a build catalog (classname/cost/requirements/upkeep/production/storage/speed
  boosts), construction jobs, upgrades, build limits, plus a RADAR feature.
- **Buy** — purchase vehicles with configurable drop points and requirements.

Plus **Ground Command** (designate trusted players who may spend resources / order research /
manage builds), **Commitment mode** (freezes config-catalog refreshes to cut server load),
**Economy Setup Builder** asks the Resource, Research, Construction and Purchasing domain builders
to translate their Zeus-authored settings and placements into readable calls to the same public
functions used by hand-authored `MissionConfig\economyConfig.sqf`. Portable
catalogue strings remain available through Config Copy and Import. Build Setup is for clean
authoring sessions, not mid-campaign state persistence. **Purge** remains the
runtime teardown tool.

Enabling it (OFF by default — missions that don't use it pay no cost):

```sqf
// init.sqf - runs on all machines, self-branches server authority vs. client menu:
Waldo_Economy_Enable = true;
// if true, init.sqf does: [] spawn Waldo_fnc_EcoInit;
```

Or simply drop the **`[WMP] Waldos Economy Systems`** composition (in `WMP_Compositions/`) into
the editor — its object boots the suite from its own init field, independent of the flag.

**Editor / script-time setup (no Zeus needed).** `Waldo_fnc_EcoInit` calls
`Waldo_fnc_EcoCore_applyMakerConfig`, which reads optional maker variables once on the server
authority (broadcast, so JIP/rejoining players inherit them) and applies them via the existing
import/preset functions. Set these in `initServer.sqf` (a documented block is provided there):

```sqf
// A bundled preset:
missionNamespace setVariable ["Waldo_Economy_Preset", "MEDIUM", true];   // LOW | MEDIUM | HIGH
missionNamespace setVariable ["Waldo_Economy_PresetSides", [["WEST","NATO"],["EAST","CSAT"],["GUER","AAF"]], true];
// or a full configuration exported from the Zeus "Export" tool (wins over a preset):
missionNamespace setVariable ["Waldo_Economy_ConfigString", "...", true];
// optional perf toggle:
missionNamespace setVariable ["Waldo_Economy_CommitmentMode", true, true];
```

For drag-and-go, the preset-specific compositions **`[WMP] Waldos Economy Systems - Low/Medium/High
Preset`** set `Waldo_Economy_Preset` in their object init and boot the suite. Place only one
Economy Systems object per mission.

**Full hand-authored economy (`MissionConfig\economyConfig.sqf`).** For complete control, makers edit
`MissionConfig\economyConfig.sqf` — the dedicated authoring file (registered as
`Waldo_fnc_EcoMakerSetup`, run once on the authority by `applyMakerConfig` after presets). It
defines catalogs and places world objects via the server-authoritative helpers, e.g.
`addResourceType`, `setResearchCatalog`, `setBuildCatalog`, `setPurchaseCatalog`,
`createResourceZone`, `spawnResourceCrate`, `spawnResearchCenter`, `createDropPoint`. It ships a
gated worked example (`_useExample`). Editor-placed vanilla objects can be designated from their
init field (no mod required — true Eden modules need an addon, which WMP is not):
`[this] call Waldo_fnc_EcoResearch_registerCenter` (on a `Land_Research_HQ_F`),
`Waldo_fnc_EcoBuy_registerTerminal` (`Land_Laptop_unfolded_F`), and
`Waldo_fnc_EcoBuild_registerConstructionVehicle` (any vehicle).

**Architecture:** the suite is 449 functions registered under `class Waldo` in
`WaldosFunctions.sqf` across six sub-namespaces, callable as
`Waldo_fnc_EcoCore_*` (shared infra: Zeus menu/dialogs/parsing/commitment),
`Waldo_fnc_EcoResource_*`, `Waldo_fnc_EcoResearch_*`, `Waldo_fnc_EcoBuild_*`,
`Waldo_fnc_EcoBuy_*`, and `Waldo_fnc_EcoCommand_*`. The bootstrap is `Waldo_fnc_EcoInit`
(`MissionScripts/EconomySystems/economyInit.sqf`). Global state uses the `WaldoEco<System>_`
variable prefix. World objects are tagged by class — resource crate `Land_PlasticCase_01_medium_F`,
research center `Land_Research_HQ_F`, purchase terminal `Land_Laptop_unfolded_F`, plus
construction vehicles. Economy authoring forms always open in a transparent modal
child display, including over Zeus, so the visible curator context remains available
without allowing its map or shortcuts to steal form input.

Player-facing Economy actions are installed through ACE when available and
through a linked vanilla `addAction` at the same time. The same dual-surface
policy applies to loadout-save points and field procedures, where the vanilla
entry is also a useful discoverability cue. Party tables use the same linked
ACE plus vanilla policy. Complex operational trees such as MHQ, Quartermaster
and VVD remain ACE-first and use vanilla only when ACE is unavailable. Both
routes must call the same guarded function.
Dynamic Economy
dialogs are fitted to a protected safe-zone rectangle and use the WMP operations
console treatment. Construction intentionally converts and consumes its source
vehicle; the confirmation UI warns before the action and a timed notice names
the vehicle consumed afterward.

**Multiplayer / authority model.** All shared state (catalogs, side resources, zones, jobs) and all
global world-object/marker creation are gated by `Waldo_fnc_EcoCore_canRunAuthority` /
`canRunBackgroundAuthority`, which return **`isServer`** — so the server is the single authority and
the background loops (income, production, research progress, request processing) run exactly once for
the mission. Client-only work (ZEN module registration, ACE action setup, dialogs, request
*publishing*) is gated by `hasInterface`. Because ZEN custom-module code runs on the **curator's
client**, the seven object-creation functions (research center, resource crate, resource zone,
building, construction vehicle, purchase laptop, drop point) **forward themselves to the server via
`remoteExec [..., 2]`** when called off the authority, so placement works on a **dedicated** server,
not just SP/listen-host. When editing economy code: mutate shared state only under `canRunAuthority`
and broadcast it (`setVariable [..., true]`); never gate client-local work on `canRunAuthority`; and
route any new world-object creation through the authority the same way.

**Operational notes for makers:**
- `Waldo_fnc_EcoCore_isActive` returns whether the suite is running (gate dependent scripts on it).
- Failed player actions (insufficient resources / unmet requirements / no drop point) now report via
  `systemChat` to the actor (`Waldo_fnc_EcoCore_notifyActor`) instead of failing silently.
- **Commitment mode** is a performance toggle: ON freezes the live config-catalog refresh polling in
  the Zeus menus to cut server load — turn it on once a mission's economy is configured. It does not
  affect gameplay, only editing of catalogs.
- **Purge** is intended to remove the suite for the rest of the mission (it sets a broadcast purged
  flag that also stops JIP players re-initialising); it is not a "reset" — restart the mission to run
  the economy again after a purge.

### Waldos Mini Games (table games + interaction challenges)

Two complementary systems under one feature. Full guide:
https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Mini-Games

**1. Table games (multiplayer).** A seated party-games engine — twelve games (Battleship, Who's Who:
Vehicles, Shotgun Roulette, Blackjack, Texas Hold'em, Five-Card Draw, Liar's Dice, Chess, Checkers,
Connect Four, Rock Paper Scissors, UNO). Players
walk up to a supported table object, take a seat (up to four), vote for a game and play. Server is
the authority; each client runs a UI/discovery loop; JIP-safe. Enable in `init.sqf`:

```sqf
Waldo_MiniGames_Enable = true;             // installs the table engine
if (Waldo_MiniGames_Enable) then {
    [] call Waldo_fnc_MiniGamesInit;
};
```

Tables are detected by class (`Land_CampingTable_F`, `Land_CampingTable_small_F`,
`Land_CampingTable_small_white_F`, `Land_TablePlastic_01_F`). Tuning constants (`Waldo_MG_CFG_*`,
including `Waldo_MG_CFG_TABLE_CLASSES`) live at the top of `MissionScripts/MiniGames/engine/config.sqf`.

**2. Field equipment procedures (single-player, generic hook).** Ten pass/fail procedures gate any
object interaction: `wirecut`, `minesweeper`, `keypad`, `lockpick`, `circuit`, `repair`, `radiotune`,
`pressure`, `sequence`, and `commandinput`. Each presents distinct diegetic equipment rather than a shared minigame
window. The common core owns responsive safe-zone layout, integrated operating cards, timers,
accessibility preferences, abort confirmation, cleanup, and exactly-once resolution. Procedures
register on first use and work with `Waldo_MiniGames_Enable = false`.

Mission makers should normally use the one-line preset wrapper from an object's Eden init field:

```sqf
[this, "repair"] call Waldo_fnc_MiniGameInteractionSetup;
```

`Waldo_fnc_MiniGameInteractionSetup` supplies the action, equipment profile, icon and default config,
allows retries after failure, consumes the action after success, and broadcasts
`Waldo_MG_InteractionState`, `Waldo_MG_InteractionResult`, and the legacy
`Waldo_MG_InteractionComplete` / `Waldo_MG_InteractionFailed` booleans. Attempts are acquired by the
server and exclusively locked; ACE is the preferred action path, with vanilla `addAction` using the
same state. Legacy option arrays remain valid.
New hashmap profiles support `preset`, `actionTitle`, `manufacturer`, `model`, `title`, `objective`,
activation/result wording, and operational options. `difficulty` accepts `easy`, `standard`, `hard`,
or `expert`; a supplied positional `config` overrides it. Difficulty profiles may change workload,
tolerance and time, but must never reduce legibility or remove accessible state cues. Layout positions
and semantic colours stay template-owned so mission customization cannot produce clipped or
colour-only states.

Mission-maker presentation hashmaps may set curated `preset` and `skin` values plus `actionTitle`,
`manufacturer`, `model`, `title`, `briefing`, `objective`, `activation`, `controls`, `hint`,
`statusText`, result/abort wording, `soundProfile`, and an optional vanilla or mission texture.
Accepted skins are `default`, `olive`, `charcoal`, `sand`, `naval`, and `hazard`; sound is
`equipment` or `silent`. Do not expose raw control positions or semantic colours: equipment templates
own layout and accessible state signalling. Operational difficulty uses the curated `difficulty`
profile or a mission-authored positional `config`.
Four original generated 1024px JPEG material sheets live in `InteractionsMinigames/Themes/Textures`,
but bitmap materials are disabled by default. Procedural Arma shapes, seams, fasteners, instruments,
labels and states form the complete primary interface. Mission makers may opt in with
`texturePreset` (`olive`, `charcoal`, `naval`, or `sand`) or an explicit `texture`; opacity is clamped
to `0..0.32` (default `0.14`). Never put operational labels or state into a bitmap: those must remain
accessible Arma controls.

- `Waldo_fnc_BombDefuseSetup` — ready-made wrapper: adds a "Defuse Bomb" interaction (wire-cut
  challenge) with detonate-on-failure. `[this] call Waldo_fnc_BombDefuseSetup;` in an object's init
  field, or pass an options array (`wireCount`, `timeLimit`, `detonateOnFailure`, `explosive`, …).
- `Waldo_fnc_MiniGameInteraction` — the generic hook: `[object, challengeId, config, onSuccess,
  onFailure, options]`. Call from the object's **init field** (runs on all machines). The
  success/failure callbacks run on the **server** (each gets `[object, actor, success, result]`) so
  they can drive authoritative outcomes; existing three-argument callbacks remain compatible. The
  challenge plays only on the accepted actor's client and reports its owner-bound attempt ID back.
- `Waldo_fnc_MiniGameInteractionGetState`, `Waldo_fnc_MiniGameInteractionStateIs`, and
  `Waldo_fnc_MiniGameInteractionGetResult` are unscheduled, side-effect-free readers suitable for
  ACE conditions. `Waldo_fnc_MiniGameInteractionReset` is server-only; normal reset refuses
  `RUNNING`, while forced reset invalidates the current attempt.
- `Waldo_MG_InteractionStateChanged` is the global CBA event with payload
  `[object, state, result]`. Broadcast variables are written before the event and callback.
- `Waldo_fnc_MiniGameChallenge` — run a challenge standalone (no object) with local callbacks.
- `Waldo_fnc_MiniGameRegisterChallenge` — add a custom challenge (opener contract `[_config, _resolve]`).
- `Waldo_fnc_MiniGameInteractionTableSetup` — opt-in separate Field Equipment picker on a table;
  procedures remain local and do not enter party voting, readiness, seating, or active-game state.
- `Waldo_fnc_MiniGameAccessibility` — local high-contrast, colourblind, large-text, outlines,
  reduced-motion, and audio-caption preferences. These never change mission difficulty or timers.
- `Waldo_fnc_MiniGameEquipmentGallery` — developer visual-review picker for all ten procedures.

**Architecture.** The table engine is ported from the community composition "Party Games Scripted" by
|LorÐ|™[Habilidade]Ðeus Ex, rebranded to the internal `Waldo_MG_` namespace. Twelve isolated games
and the shared server/client engine live across `engine/config.sqf`, `engine/core.sqf` and
`engine/games/*.sqf`; all are `#include`-d and installed
by `Waldo_fnc_MiniGamesInit`). Only the public entry points are `CfgFunctions` entries under
`class MiniGames`; the engine's `Waldo_MG_fnc_*` functions are defined at runtime by the installer, not
registered individually. The field-equipment framework is original WMP and lives separately under
`MissionScripts/InteractionsMinigames/` (`Core`, `Equipment`, `Challenges`, `Integration`, `Themes`).
When editing: keep table internals under `Waldo_MG_`/`Waldo_MG_fnc_`; keep authoritative interaction
callbacks server-side; preserve public `Waldo_fnc_MiniGame*` names; openers must resolve exactly once.

---

## description.ext — Mission Maker Checklist

The fields mission makers should always edit before using the pack:

```
author          = "YOURNAMEHERE";
onLoadName      = "Mission Pack v4.8.0";   // mission title
onLoadMission   = "YOURTEXTHERE";
maxPlayers      = 31;                       // set to your playercount
respawnDelay    = 20;                       // seconds
```

Replace `Pictures\loading.jpg` with a custom loading screen image.

**Do not change** `respawnOnStart = -1` — it is required by the loadout saving system.

---

## MissionScripts Directory Layout

- `MissionInit/` — ACRE2 radio setup, vehicle action setup, team colour helpers, briefing document templates
- `MissionInit/Jamming/` — Localised radio jamming for ACRE2 & TFAR (registry, create/toggle/remove, per-mod engines, UAV jamming, shared factor helper, EW toolkit + feedback HUD)
- `MissionInit/ElectronicWarfare/` — EMP burst (`Waldo_fnc_EMP`) and signal trackers / C-Track (`Waldo_fnc_Tracker`)
- `Logistics/` — The largest module: supply/medical crates, loadout saving, MHQ, teleport, fortification, vehicle camo, virtual vehicle depot, map location tools
- `AiScripting/` — AI skill adjustment (`AITweak`) and convoy system (`SimpleAiConvoy`)
- `MissionFlowAndUi/` — ENDEX, info text overlays, respawn messages, timed hints
- `MissionFlowAndUi/create3DMarker.sqf`, `init3DMarkers.sqf`, `remove3DMarker.sqf` — server-owned, JIP-safe custom 3D icon/text markers using one shared renderer
- `Paradrop/` — HALO and static-line jump system (8 scripts: setup, equipment simulation, vehicle jump config)
- `ZenModules/` — Zeus Enhanced custom modules for logistics and ENDEX
- `CombatSystems/` — airborne gunship support, explosive breaching, Dynamic AA and Dynamic AO
- `EnvironmentalSystems/` — hazardous environments and tree felling
- `MedicalSystems/` — patient treatment feedback
- `Persistence/` — optional INIDBI2-backed persistence
- Cross-cutting optional features live with their owning domain: accessibility and tactical display under `MissionFlowAndUi/`, emergency dismount under `MissionInit/VehicleActionsSetup/`, field resupply under `Logistics/`, object transforms under `MissionMakerResourceScripts/`, and runtime controls under `ZenModules/`
- `EconomySystems/` — Waldos Economy Systems (Resource / Research / Build / Buy + Ground Command). 449 `Waldo_fnc_Eco*` functions across `Core/`, `Resource/`, `Research/`, `Build/`, `Buy/`, `Command/`, plus the `economyInit.sqf` bootstrap (`Waldo_fnc_EcoInit`)
- `MiniGames/` — seated party-game installer and multiplayer engine only.
- `InteractionsMinigames/` — field-equipment procedures, equipment themes, accessibility core, object/table integration, and all ten challenge implementations.
- `ThirdPartyScripts/` — Headless client and player marker integrations (disabled by default via commented-out line in `init.sqf`)

---

## Mod API Reference

This section documents how each mod integrates with WMP so scripts can be read and extended without prior Arma 3 mod knowledge.

### CBA_A3 (Community Base Addons) — Required

CBA is the event system backbone. WMP uses it for all unit lifecycle hooks.

**Key functions used:**

| Function | Where used | What it does |
|---|---|---|
| `CBA_fnc_addClassEventHandler` | `initPlayerLocal.sqf`, `AISkillAdjustmentSystem.sqf` | Fires a callback whenever any unit of the given class triggers an event (e.g. "Respawn", "Killed", "InitPost"). Used to re-apply loadouts on respawn and to initialise AI skills for Zeus-spawned units. |
| `CBA_fnc_addEventHandler` | `initPlayerLocal.sqf` | Fires on a named game event (e.g. `ace_arsenal_displayClosed`). Used for the optional "save loadout on arsenal close" feature. |
| `CBA_fnc_execNextFrame` | `ZenModules/` | Defers code by one frame — used so Zeus curator objects exist before being referenced. |
| `CBA_fnc_notify` | `Paradrop/paraEquipmentSim.sqf`, `checkForJumpSettings.sqf` | Brief on-screen notification. Used to tell jumpers what equipment was lost on exit. |
| `CBA_fnc_setPos` / `CBA_fnc_setHeight` | `teleport.sqf` | Position setters used by the teleport system. |
| `CBA_fnc_hashCreate` / `CBA_fnc_hashGet` | `GetSRChannelName.sqf` | Key-value store mapping squad callsigns to ACRE2 channel data. |

**Call pattern:** `["ClassName", "EventName", { params ["_unit"]; ... }] call CBA_fnc_addClassEventHandler`

---

### ACE3 (Advanced Combat Environment) — Required

ACE3 is the most heavily used dependency (~80 call sites across 20+ files). WMP uses it for all player-facing interaction menus, medical system, logistics, and weapon safety.

**Interaction menus** — every deployable action (MHQ, vehicle camo, construction, quartermaster, paradrop settings) is an ACE scroll-wheel action:
```sqf
private _action = [id, displayName, icon, code, condition, insertCode]
    call ace_interact_menu_fnc_createAction;
[object, isVehicleAction, pathArray, _action]
    call ace_interact_menu_fnc_addActionToObject;
```

**Progress bars** — timed deploy/teardown actions use:
```sqf
[duration, title, condition, completionCode, cancelCode]
    call ace_common_fnc_progressBar;
```

**Arsenal** — limited arsenals restricted to mission loadouts:
```sqf
[box, true]          call ace_arsenal_fnc_initBox;         // full ACE Arsenal on a box
[box, itemsArray]    call ace_arsenal_fnc_addVirtualItems; // restrict to specific items
```

**Cargo / dragging** — crates are made portable:
```sqf
[object, spaceValue] call ace_cargo_fnc_setSpace;
[object, sizeValue]  call ace_cargo_fnc_setSize;
[object, true]       call ace_dragging_fnc_setDraggable;
[object, true]       call ace_dragging_fnc_setCarryable;
```

**Fortification:**
```sqf
[side, objectClassArray, budget] call ace_fortify_fnc_registerObjects;
[side, delta]                    call ace_fortify_fnc_updateBudget;
```

**ENDEX (weapon lock + healing):**
```sqf
[player, true] call ace_safemode_fnc_lockSafety;
[player]       call ace_medical_treatment_fnc_fullHeal;
```

**Drag/carry weight limits** (set in `init.sqf`):
```sqf
ACE_maxWeightDrag  = 10000;
ACE_maxWeightCarry = 6000;
```

**Mod detection pattern** — used throughout to guard ACE-dependent code:
```sqf
if (isClass(configFile >> "CfgPatches" >> "ace_main")) then { ... };
if (isClass(configFile >> "CfgPatches" >> "ace_medical")) then { ... };
```

**Key ACE object variables:**
- `ace_medical_isMedicalFacility` — marks a crate as a field hospital
- `ace_medical_isMedicalVehicle` — marks a vehicle as medical
- `ACE_isEngineer` / `ace_medical_medicClass` — read by briefing documents

---

### ACRE2 (Advanced Combat Radio Environment 2) — Default radio mod

ACRE2 provides realistic radio simulation. WMP auto-assigns radios per squad on spawn. All ACRE2 scripting lives in `MissionScripts/MissionInit/ACRE2/`.

**Detection guard** — every ACRE2 script exits immediately if the mod is absent:
```sqf
if !(isClass(configFile >> "CfgPatches" >> "acre_main")) exitWith { systemChat "ACRE2 Mod Not Enabled"; };
```

**Radio classnames and stereo assignment:**

| Class | Type | Ear |
|---|---|---|
| `ACRE_PRC343` | Short-range squad radio | LEFT |
| `ACRE_PRC152` | Long-range handheld | RIGHT |
| `ACRE_PRC148` | Long-range handheld (alt) | RIGHT |
| `ACRE_PRC117F` | HF backpack/vehicle radio | CENTER |

**Key API calls:**
```sqf
// Check radio model
[radioObj, "ACRE_PRC343"] call acre_api_fnc_isKindOf;

// Tune channel and set stereo position
[radioObj, channelNumber] call acre_api_fnc_setRadioChannel;
[radioObj, "LEFT"]        call acre_api_fnc_setRadioSpatial; // LEFT / RIGHT / CENTER

// Get all radios currently carried by the player
[] call acre_api_fnc_getCurrentRadioList;

// Configure preset channel fields (used in legacy init path)
[radioObj, presetName, channelIndex, "label", value]       call acre_api_fnc_setPresetChannelField;
[radioObj, presetName, channelIndex, "frequencyTX", value] call acre_api_fnc_setPresetChannelField;

// Apply a preset to radios
[radioObj, presetName] call acre_api_fnc_setPreset;

// Wait until ACRE has fully initialised before assigning channels
waitUntil { [] call acre_api_fnc_isInitialized };
```

**Jamming (custom signal processing):** ACRE2 has no jammer API. The only hook is a single custom signal function — WMP's radio jamming (`Waldo_fnc_JammingAcreSignal`) owns it:
```sqf
// Override / reset ACRE2's signal calculation (only ONE custom func can exist at a time):
[_myFunc] call acre_api_fnc_setCustomSignalFunc;     // _myFunc gets [freqMHz, powerMw, rxRadioId, txRadioId], returns [percent(0-1), dBm]
[{}]      call acre_api_fnc_setCustomSignalFunc;     // reset to default
_base = [_freq, _power, _rxId, _txId] call acre_sys_signal_fnc_getSignalCore;  // ACRE2's own baseline result
_pos  = [_radioId] call acre_sys_radio_fnc_getRadioPos;                        // ASL position of a radio
```
The custom hook is called **only** under the *LOS Multipath* (default) or *Arcade* signal models.

**Babel (multilingual) API** (`BabelActivation.sqf`):
```sqf
[languageName]          call acre_api_fnc_babelAddLanguageType;
[unit, languagesArray]  call acre_api_fnc_babelSetSpokenLanguages;
```

**Known ACRE2 limitation:** channel _naming_ via `setPresetChannelField` `"label"` does not display in-game — it causes radio inconsistency. Channel names are maintained only in the CEOI map entry; radios are numbered only. The label-setting code in `ACRE2Init.sqf` is commented out for this reason.

**Initialisation sequence in `ACRE2Init.sqf`:**
1. `Waldo_fnc_SquadLevelRadios` runs first to compute SR channel assignments per callsign and sets `Waldo_ACRE2Setup_CallsignChannelAssignments_flag`
2. `waitUntil { acre_api_fnc_isInitialized && callsign flag }` blocks until both are ready
3. PRC343 (SR) assigned from the computed callsign map → LEFT ear; removed from radio list
4. PRC152/148/117F (LR) assigned in order from the `_RadioAssignments` channel array → RIGHT/CENTER; array is popped as each radio is assigned to prevent duplicates
5. Loadout saved via `Waldo_fnc_SaveLoadout` so channels persist through respawn
6. CEOI populated via `Waldo_fnc_CreateACRECEOI`

---

### TFAR (Task Force Arrowhead Radio) — Optional, no scripting required

TFAR has **inherent Eden Editor support** — it assigns radios via the 3Den unit properties panel, not through scripts. WMP has zero TFAR function calls.

The one point of integration: `missionFileLookup.sqf` reads the `radio` inventory slot from `mission.sqm` when scraping unit loadouts. This slot captures TFAR radio classnames placed via Eden, so they flow into supply crates automatically alongside all other items — no extra scripting needed.

**Jamming:** TFAR has no signal hook, but it exposes client-side unit variables that WMP's jamming loop (`Waldo_fnc_JammingTfarLoop`) drives while a player is inside a jammer field (detected via `task_force_radio` or `tfar_core` in `CfgPatches`):

| Variable | Type | Effect |
|---|---|---|
| `tf_receivingDistanceMultiplicator` | unit var (client) | Scales receive range; WMP sets it toward `0` to kill reception. |
| `tf_sendingDistanceMultiplicator` | unit var (client) | Scales transmit range; WMP sets it toward `0` to kill outbound comms. |
| `tf_unable_to_use_radio` | unit var (client) | `true` fully disables the radio (set at near-total jamming). |

The loop only restores these to their defaults (`1.0` / `false`) when the player leaves the field, so it never clobbers other scripts while un-jammed. TFAR jamming is broadband (no per-band filter).

---

### Zeus Enhanced — Optional

Zeus Enhanced adds a custom module category inside the Zeus editor. WMP exits silently if ZEN is absent:
```sqf
if !(isClass(configFile >> "CfgPatches" >> "zen_main")) exitWith {};
```

**Two ZEN functions are used:**
```sqf
// Register a module — appears in Zeus editor under the given category
[category, moduleName, code, iconPath] call zen_custom_modules_fnc_register;

// Show a parameter input dialog to the Zeus operator
[title, parametersArray] call zen_dialog_fnc_create;
```

**Registered modules** (all under "Waldos Mission Modules"):
- Player Supply Crate → calls `Waldo_fnc_ZenSupplySpawner`
- Field Hospital Crate → calls `Waldo_fnc_ZenMedicalSpawner`
- Call Endex → `remoteExec ["Waldo_fnc_ENDEX", 0, true]`
- Custom Mission End → `["end1"] remoteExec ["BIS_fnc_endMission", 0, true]`
- Fortify Budget Manager → calls `Waldo_fnc_FortifyBudgetModule`
- Spawn AI Convoy → calls `Waldo_fnc_ZenConvoyModule` (turns the nearest crewed land-vehicle group into a managed convoy via `Waldo_fnc_SimpleAiConvoy`)
- Loadout Save Point → calls `Waldo_fnc_ZenLoadoutSaveModule`
- Safestart - Activate → `[true] remoteExec ["Waldo_fnc_SafeStart", 2]`
- Safestart - Go Live (Lift) → `[false] remoteExec ["Waldo_fnc_SafeStart", 2]`
- Safestart - Start Go-Live Countdown → calls `Waldo_fnc_ZenSafeStartTimer` (prompts for seconds, then `Waldo_fnc_SafeStartTimer`; HUD uses `MM:SS`)
- Radio Jammer - Place → calls `Waldo_fnc_ZenJammerPlace` (dialog: radius / falloff / strength / affected side / cone / pulsing / jam UAVs / marker; spawns an emitter and registers it via `Waldo_fnc_Jammer`)
- Radio Jammer - Toggle Nearest → calls `Waldo_fnc_ZenJammerToggle` (flips the nearest jammer on/off)
- Radio Jammer - Remove Nearest → calls `Waldo_fnc_ZenJammerRemove` (removes + deletes the nearest jammer)
- EMP Detonation → calls `Waldo_fnc_ZenEMP` (dialog: radius / duration; detonates an EMP via `Waldo_fnc_EMP`)
- Plant Signal Tracker → calls `Waldo_fnc_ZenTracker` (tags the nearest unit/vehicle, tracked by a chosen side, via `Waldo_fnc_Tracker`)
- Mission Flow: Send Notification → calls `Waldo_fnc_ZenNotify` (dialog: title / message / type / duration / placement / audience; routes through `Waldo_fnc_ZenNotifyServer` to `Waldo_fnc_NotificationBroadcast`)

---

## Codebase Conventions

### In-engine Arma UI validation

SQF/config validation is necessary but does not validate rendered controls. For
interaction-equipment UI work, use the disposable VR mission documented in
`releaseVerificationAndDeployment/interactionEquipmentQA/README.md`.

- Launch `launch_interaction_ui_qa.ps1` in `Interactive` mode for manual visual
  and input review, `Active -Challenge <id> -Difficulty <level>` for a focused
  procedure, or `Automated` for all ten briefing/active/mechanics checks.
- Use `Automated -AllDifficulties` for the complete 40-case easy, standard,
  hard, and expert matrix. Automation must operate real input/state functions,
  not assign solved values or invoke the common finish callback.
- Every QA launch must use `-noBattlEye`; the launcher supplies it by default.
- Read the newest Arma RPT and require zero SQF errors and zero runtime layout
  findings.
- Use `capture_interaction_ui.ps1` for GUI-inclusive, DPI-aware window captures;
  Arma's scripted screenshot does not capture the GUI.
- Scale layouts from the complete Arma safe zone. Never assume `0..1` represents
  the visible viewport, because UI scale and aspect ratio can extend the safe
  zone beyond those coordinates.

For branch-wide release and deployment verification, use the checked-in mission
and process in `releaseVerificationAndDeployment/fullArmaAudit/`. The canonical
launcher is `launch_pr_review_audit.ps1`; it stages the exact release allowlist
around the proven `FullArmaAudit.VR` scenario and starts a hosted multiplayer
session through the normal CfgFunctions/init/JIP lifecycle. Always retain
`-noBattlEye`, CBA, ACE, ZEN and ACRE2, use 2560x1440, and leave mutating
automation disabled for manual feature review. Follow
`fullArmaAudit/PROCESS.md` for the required mod order, RPT checks, external UI
captures, focused retests and final sign-off record.

### Script file header

Every `.sqf` file in `MissionScripts/` opens with a documentation block:
```sqf
/*
 * Author: WaldoTheWarfighter
 * One-line description of what this script does.
 *
 * Arguments:
 * _param1 - Type - Description
 * _param2 - Type - Description (optional, default: value)
 *
 * Return Value:
 * Nothing / description of return
 *
 * Example:
 * [this, true, false] call Waldo_fnc_FunctionName;
 */
```
Read this header before editing any script — it documents all valid arguments.

### Documentation standard (in-file, feature, wiki)

WMP holds a single documentation standard, codified in the wiki **Coding-Standards** page. Apply it to all new or changed work:

- **In-file:** every `.sqf` opens with the header block above (description / Arguments with types+defaults / Return Value / Example). If a file starts with `#include` lines, the header goes *after* them (the validator rejects `#include` after a block comment). Preserve third-party attribution; never claim authorship of third-party scripts.
- **Feature documentation:** when adding/changing a user-facing feature, document it in **all four** places with identical terminology — in-file headers, a `CLAUDE.md` *Feature Configuration Guide* section (+ a *MissionScripts Directory Layout* line if it adds a folder), a `README.md` *Pack Features* bullet, and a wiki page.
- **Wiki page:** lead with an *Associated Files* line, then overview → setup → usage/options (tables) → examples → see-also. Large features get a hub page plus one sub-page per sub-system (see the Waldos Economy Systems pages). Write for mission makers, not scripters.

When adding a feature, run the checklist in the wiki Coding-Standards page (headers, registration, CLAUDE.md, README, wiki, validators).

### Argument parsing

All functions use `params` at the top to unpack `_this`:
```sqf
// Required params
params ["_target", "_side"];

// With optional params and defaults
params ["_target", ["_audio", false], ["_logistics", false], ["_direction", 180]];
```

### Guard clauses

Scripts open with early-exit guards before any logic:
```sqf
if !(isServer) exitWith {};                                          // server-only script
if !(hasInterface) exitWith {};                                      // client-only script
if !(isClass(configFile >> "CfgPatches" >> "ace_main")) exitWith {}; // mod not loaded
```

### Execution locality

- `call` — synchronous, runs in current thread, returns a value
- `spawn` — starts a new thread, non-blocking, cannot return a value; used for long-running or sleep-containing code
- `remoteExec` — runs on other machines: `[args, "functionOrCommand", targets] remoteExec`
  - target `0` = all machines; `-2` = all clients; `2` = server only
  - third arg `true` = persistent (re-runs for JIP players)

### Global variables

All global state is stored in `missionNamespace`:
```sqf
missionNamespace setVariable ["Waldo_VARNAME", value, true]; // true = broadcast to all clients
missionNamespace getVariable ["Waldo_VARNAME", defaultValue];
```

Prefix convention: `Waldo_` for WMP variables, `Logi_` for logistics system variables, `WALDO_` (all caps) for flags/thresholds.

### Function naming and registration

All functions follow `Waldo_fnc_FunctionName` (CamelCase after the prefix). Adding a new function requires:
1. Create the `.sqf` file in the appropriate `MissionScripts/` subdirectory
2. Add a matching class entry to `MissionScripts/WaldosFunctions.sqf` — the class name must match the suffix exactly

### Formatting

- **No tabs** — spaces only. The validator flags tab characters in SQF files.
- Strings use either `"double"` or `'single'` quotes — both are valid in SQF; be consistent within a file.
- Statements end with `;` — the validator checks for missing semicolons after closing `}`.

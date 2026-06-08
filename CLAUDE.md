# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

WaldosMissionPack (WMP) is an Arma 3 mission scripting framework. It is not a traditional software application — it is a collection of SQF scripts, config files, and tooling that mission makers drop into an Arma 3 multiplayer mission to get automated logistics, radio setup, paradrop, AI tweaks, and other features. The framework is used by ~40+ milsim units.

Required Arma 3 mods: **CBA_A3**, **ACE 3**. Optional: ACRE 2, TFAR, Zeus Enhanced, LAMBS mods.

## Validation & Linting

These run automatically on every push/PR via GitHub Actions (`.github/workflows/testing.yml`):

```bash
# SQF syntax validation (bracket matching, semicolon checks) — must pass
python3 releaseVerificationAndDeployment/sqf_validator.py

# Config/HPP bracket validation — must pass
python3 releaseVerificationAndDeployment/config_style_checker.py

# sqflint linter — informational only, continues on error due to false positives
```

Both Python validators exit non-zero on errors, blocking CI. Run them locally before pushing SQF changes.

## Build & Release

```bash
# Standard dev build (interactive — prompts before packing)
python3 releaseVerificationAndDeployment/build.py

# CI/automated build (non-interactive)
python3 releaseVerificationAndDeployment/build.py --deploy

# Build a specific variant (e.g. patch, exemplar mission)
python3 releaseVerificationAndDeployment/build.py --build config_ExemplarMission.json
```

Build config is `releaseVerificationAndDeployment/config.json`. It defines what gets excluded from the zip (`notlist`). Output goes to `release/`. The deploy workflow (`.github/workflows/deploy.yml`) triggers on GitHub release publish and uploads 5 artifacts: main WMP pack, patch file, Compositions, Unit Insignias, and Exemplar Mission.

## Architecture

### How Scripts Become Callable Functions

All functions are declared in `MissionScripts/WaldosFunctions.sqf` via Arma 3's `CfgFunctions` class system. This file is `#include`-d by `description.ext`. The declaration maps a class name to a `.sqf` file path, letting Arma 3 preload them as callable functions.

**Naming convention:** every function is `Waldo_fnc_FunctionName` (CamelCase after the prefix). The class name in `WaldosFunctions.sqf` must match the function name suffix exactly.

### Execution Flow

```
Mission load
  └─ description.ext  ──► #includes WaldosFunctions.sqf (registers all Waldo_fnc_*)
        │
        ├─ initServer.sqf          (server only)
        │     └─ Waldo_fnc_SideBaseLoadoutSetup  ← scans mission.sqm for unit loadouts
        │
        ├─ init.sqf                (all clients + server)
        │     └─ Radio, AI tweaks, vehicle init, briefing docs, team colours, info text
        │
        └─ initPlayerLocal.sqf     (per-player, each join/respawn)
              └─ Saves inventory, adds vehicle flip action, restores loadout on respawn
```

### MissionScripts Directory Layout

- `MissionInit/` — ACRE2 radio setup, vehicle action setup, team colour helpers, briefing document templates
- `Logistics/` — The largest module: supply/medical crates, loadout saving, MHQ, teleport, fortification, vehicle camo, virtual vehicle depot, map location tools
- `AiScripting/` — AI skill adjustment (`AITweak`) and convoy system (`SimpleAiConvoy`)
- `MissionFlowAndUi/` — ENDEX, info text overlays, respawn messages, timed hints
- `Paradrop/` — HALO and static line jump system (8 scripts covering setup, equipment simulation, vehicle jump config)
- `ZenModules/` — Zeus Enhanced custom modules for logistics and ENDEX
- `ThirdPartyScripts/` — Headless client and player marker integrations (disabled by default in `init.sqf`)

### Key Conventions

- **No tabs** — the SQF validator flags tab characters (currently logged, not counted as errors, but avoid them). Use spaces.
- **Function calls use `call` or `spawn`**: `[] call Waldo_fnc_X` for synchronous, `[] spawn Waldo_fnc_X` for threaded.
- **Mission-scoped globals** use `missionNamespace setVariable ["Waldo_VARNAME", value, true]`. The `true` broadcasts to all clients.
- **The `WALDO_INIT_COMPLETE` flag** (set at the end of `init.sqf`) signals that all client-side init has finished. Scripts that depend on full init should `waitUntil` on this variable.
- **`description.ext`** controls max players (default 31), respawn type (`BASE`, 20s delay), and custom sounds. Edit here to change mission-level settings.
- Adding a new function requires: (1) create the `.sqf` file in the appropriate `MissionScripts/` subdirectory, (2) add the class entry to `WaldosFunctions.sqf`.

### WMP_Compositions

Pre-built Arma 3 compositions in `WMP_Compositions/` are standalone examples showing how to wire up WMP features. They are packaged separately in releases and are not loaded during normal mission execution.

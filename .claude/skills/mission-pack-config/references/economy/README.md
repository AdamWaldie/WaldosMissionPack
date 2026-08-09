# Waldos Economy Systems — index

A self-contained, **pub-Zeus** RTS-style economy suite: Resource / Research /
Build / Buy, plus Ground Command. 449 functions across six sub-namespaces —
this is the largest single system in WMP, so read only the sub-file(s) the
request actually touches:

| Sub-namespace | File | Covers |
|---|---|---|
| Core / bootstrap / Zeus infra | `core.md` | Enabling the suite, presets, commitment mode, Zeus menu/dialog infra, authority model |
| Resource | `resource.md` | Resource types, crates, capturable zones |
| Research | `research.md` | Research Center, catalog, prerequisites |
| Build | `build.md` | Build catalog, construction, upgrades, RADAR |
| Buy | `buy.md` | Purchase terminals, drop points |
| Ground Command | `command.md` | Trusted-player permissions for spending/research/build |

**Always start with `core.md`** even for a single-subsystem request — it
covers the enable flag, the authority model every subsystem depends on, and
whether Zeus Enhanced is even required for what the user wants to do.

## Zeus Enhanced dependency

Without ZEN, the suite still runs server-side (income, research, production,
request handling) but exposes **no in-game authoring menu** — the mission
maker must hand-author `MissionConfig/economyConfig.sqf` instead. Check
`../mod-detection.md` before assuming the Zeus menu route is available.

In the Zeus module browser the suite's own module category is labelled
**"WMP Economy Systems"** (a rename from the older "Waldos Economy
Systems" category label) — the feature/system itself is still called
Waldos Economy Systems everywhere else (docs, README, compositions).

## Architecture note (for context, not something to reconfigure)

Registered under `class Waldo` in `WaldosFunctions.sqf`, callable as
`Waldo_fnc_EcoCore_*`, `Waldo_fnc_EcoResource_*`, `Waldo_fnc_EcoResearch_*`,
`Waldo_fnc_EcoBuild_*`, `Waldo_fnc_EcoBuy_*`, `Waldo_fnc_EcoCommand_*`.
Bootstrap is `Waldo_fnc_EcoInit`
(`MissionScripts/EconomySystems/economyInit.sqf`). Global state uses the
`WaldoEco<System>_` variable prefix.

_Associated Files: MissionScripts\EconomySystems\ (the `Waldo_fnc_Eco*` functions), `Waldo_fnc_EcoInit`, `economyConfig.sqf`_

Waldos Economy Systems is a **pub-Zeus, RTS-style economy suite** built into the pack. It lets you run a resource economy, a tech tree, base construction, and a vehicle store entirely from inside Zeus — no scripting needed by the operator, and no Eden work needed beyond turning it on. It works for any curator, including a player-controlled Zeus.

This is the hub page. Each system has its own tutorial:

## Feature pages

* **[Setup & Configuration](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Economy-Systems-Setup-And-Configuration)** — enable it, presets, config strings, the `economyConfig.sqf` authoring file, editor designation helpers, and compositions.
* **[Resource System](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Economy-Systems-Resource-System)** — define resources, crates, capturable income zones, storage limits.
* **[Research System](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Economy-Systems-Research-System)** — a Research Center, custom research, costs, prerequisites, exclusivity.
* **[Build System](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Economy-Systems-Build-System)** — buildings, construction, upgrades, production, upkeep, RADAR.
* **[Buy System](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Economy-Systems-Buy-System)** — purchase vehicles, drop points, requirements.
* **[Ground Command & Tools](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Economy-Systems-Ground-Command-And-Tools)** — trusted-player permissions, Commitment mode, Export/Import, Purge.

## What it is at a glance

| System | What players do |
|---|---|
| Resource | Collect resource crates and capture zones that passively generate resources for their side. |
| Research | Spend resources at a Research Center to unlock research (with prerequisites). |
| Build | Construct and upgrade buildings that produce resources, store them, boost speeds, or reveal enemies. |
| Buy | Purchase vehicles at a terminal; they appear at a configured drop point. |

## Quick start

1. Enable the suite — set `Waldo_Economy_Enable = true;` in `init.sqf`, **or** place a `[WMP] Waldos Economy Systems` composition (a preset variant gives you a working economy instantly).
2. Open Zeus — a new **Waldos Economy Systems** root appears in the Zeus tree.
3. Configure live, or pre-author everything in `economyConfig.sqf` so it loads automatically.

See **[Setup & Configuration](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Economy-Systems-Setup-And-Configuration)** for the full walkthrough.

## Architecture (for scripters)

All functionality is registered under `class Waldo` in `WaldosFunctions.sqf` across six sub-namespaces:

| Namespace | Purpose |
|---|---|
| `Waldo_fnc_EcoCore_*` | Shared infrastructure — Zeus menu/dialogs, parsing, commitment mode, curator registration |
| `Waldo_fnc_EcoResource_*` | Resources, zones, crates, markers, storage |
| `Waldo_fnc_EcoResearch_*` | Research catalog, queue, requirements |
| `Waldo_fnc_EcoBuild_*` | Build catalog, construction, upgrades, production |
| `Waldo_fnc_EcoBuy_*` | Vehicle purchases and drop points |
| `Waldo_fnc_EcoCommand_*` | Ground Command authority |

The bootstrap is `Waldo_fnc_EcoInit`. Global state uses the `WaldoEco<System>_` variable prefix. World objects are recognised by class: resource crate `Land_PlasticCase_01_medium_F`, Research Center `Land_Research_HQ_F`, purchase terminal `Land_Laptop_unfolded_F`, plus tagged construction vehicles.

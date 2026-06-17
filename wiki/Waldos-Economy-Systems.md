_Associated Files: MissionScripts\EconomySystems\ (449 `Waldo_fnc_Eco*` functions) and `Waldo_fnc_EcoInit` (economyInit.sqf)_

Waldos Economy Systems is a **pub-Zeus, RTS-style economy suite** built into the pack. It lets you run a resource economy, a tech tree, base construction, and a vehicle store entirely from inside Zeus — no scripting needed by the operator, and no Eden work needed beyond turning it on. It works for any curator, including a player-controlled Zeus.

It was adapted into WMP from the community "Grand Resource System" scripted composition and fully rebranded.

## The Four Systems

* **Resource** — Define your own resources (give each a name, colour, map icon and a per-side storage cap). Spawn collectable resource crates, and place **capturable zones** that passively generate resources for whoever owns them. Zones can have a finite deposit so they run dry.
* **Research** — Place a **Research Center** where a side spends resources on custom research. Research can have costs, prerequisites, and be mutually exclusive with other research.
* **Build** — Define buildings with a classname, cost, build/research requirements, upkeep, resource production, storage capacity, and construction/research speed boosts. Includes construction jobs, upgrades, build limits, and a RADAR feature.
* **Buy** — Let players purchase vehicles, with configurable drop points and purchase requirements (resource cost, research/building prerequisites, and so on).

## Supporting Tools

* **Ground Command** — Designate trusted players as Ground Command, giving them permission to spend resources, order research, and manage/upgrade structures.
* **Commitment Mode** — When turned on, dynamic menus stop polling for config-catalog changes, reducing server load. Turn it on once you have finished configuring.
* **Export / Import** — Export your entire configuration to a text string you can save and paste back later (or share between missions).
* **Purge** — Cleanly removes the system from the mission if you no longer want it.

## Turning It On

The suite is **off by default**, so missions that don't use it pay no performance cost. Enable it in one of two ways:

**1. Drop the composition (easiest)**

Place the **`[WMP] Waldos Economy Systems`** composition from the Eden compositions list (category _Waldos Mission Pack Compositions_). Its object boots the suite from its own init field. That's it — open Zeus and use the menu.

**2. Enable it in `init.sqf`**

Find the Waldos Economy Systems block in `init.sqf` and set the flag to `true`:

```sqf
Waldo_Economy_Enable = true;
// init.sqf then runs: [] spawn Waldo_fnc_EcoInit;
```

This runs on every machine and self-branches between the server authority loops and the client Zeus menu.

## Using It In Zeus

Once enabled, open Zeus. A new root entry — **Waldos Economy Systems** — appears in the Zeus tree. From there you can:

* Configure resources, research, buildings and purchases (and Export/Import those configs).
* Place resource crates, capturable zones, Research Centers, construction vehicles and purchase terminals.
* Set side resource amounts, assign Ground Command, and toggle Commitment Mode.

World objects are recognised by class: resource crate `Land_PlasticCase_01_medium_F`, Research Center `Land_Research_HQ_F`, purchase terminal `Land_Laptop_unfolded_F`, plus tagged construction vehicles. Players interact with them through the ACE interaction menu.

## Scripting Reference

All functionality is registered under `class Waldo` in `WaldosFunctions.sqf` across six sub-namespaces:

| Namespace | Purpose |
|---|---|
| `Waldo_fnc_EcoCore_*` | Shared infrastructure — Zeus menu/dialogs, parsing, commitment mode, curator registration |
| `Waldo_fnc_EcoResource_*` | Resources, zones, crates, markers, storage |
| `Waldo_fnc_EcoResearch_*` | Research catalog, queue, requirements |
| `Waldo_fnc_EcoBuild_*` | Build catalog, construction, upgrades, production |
| `Waldo_fnc_EcoBuy_*` | Vehicle purchases and drop points |
| `Waldo_fnc_EcoCommand_*` | Ground Command authority |

The bootstrap is `Waldo_fnc_EcoInit`. Global state uses the `WaldoEco<System>_` variable prefix.

> **Note:** This suite was Alpha-stage upstream. This first WMP release focuses on rebranding and native integration; ease-of-use and stability refinements are planned for follow-up passes.

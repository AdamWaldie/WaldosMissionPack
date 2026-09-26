# Economy Setup and Configuration

> **Use this page when:** you are enabling the Economy, selecting a preset, or exporting a Zeus-authored setup to script.

_Associated Files: `init.sqf`, `initServer.sqf`, `MissionConfig\economyConfig.sqf`, `Waldo_fnc_EcoInit`, `Waldo_fnc_EcoCore_applyMakerConfig`_

| Catalog authoring | Mission setup builder |
|---|---|
| ![Resource catalog authoring](images/economy/economy-resource-config.png) | ![Economy mission setup builder](images/economy/economy-builder.png) |

This page covers how to enable and configure [Waldos Economy Systems](Waldos-Economy-Systems). You can start with a preset or define the catalogue yourself. The server applies the setup once and publishes the resulting economy to joining players.

> **Zeus Enhanced is required for the in-Zeus menu.** Every operator action is a **ZEN custom module** in the Zeus module list under the single category **"WMP Economy Systems"**. Modules are named `System - Action`, so the tutorial paths on the other pages map directly: e.g. "**WMP Economy Systems → Resource → Configure Resources**" is the module **`Resource - Configure Resources`**, and "**Research → Create Research Center**" is **`Research - Create Research Center`**. Placement modules (create crate/zone/research center, spawn building/vehicle/laptop, set drop point) spawn at the point where you drop the module on the map. Without ZEN the economy still runs on the server, but there is no in-Zeus menu.

## Quick setup: enable the suite

It is **off by default**, so missions that don't use it pay no performance cost. Turn it on whichever way is easiest for you:

* **Place a composition** from Eden's _Waldos Mission Pack Compositions_ category. No scripting or init fields are needed:
  * `[WMP] Waldos Economy Systems - Low / Medium / High Preset` starts the suite and loads a preset. Start with **Low** if you are new to the Economy.
  * `[WMP] Waldos Economy Systems` starts the suite without a preset. Configure it in Zeus or with the files below.
* **Or set one flag in `MissionConfig\missionSystemsConfig.sqf`:**
  ```sqf
  ["Waldo_Economy_Enable", true], // starts the server-owned economy runtime
  ```

Place only one Economy Systems object per mission.

| Mission setup value | Type | Shipped default | Where to change it |
| --- | --- | --- | --- |
| `Waldo_Economy_Enable` | Boolean | `false` | `MissionConfig/missionSystemsConfig.sqf`; enables the runtime, not a resource catalogue. |
| `Waldo_Economy_Preset` | String | Unset | Optional server value in `initServer.sqf`: `LOW`, `MEDIUM` or `HIGH`. |
| `Waldo_Economy_PresetSides` | Array of `[side ID, faction key]` rows | Unset | Optional server value in `initServer.sqf`; for example `[["WEST", "NATO"]]`. |
| `Waldo_Economy_ConfigString` | String | Unset | Optional server value in `initServer.sqf` containing an exported configuration. |
| `Waldo_Economy_CommitmentMode` | Boolean | Unset | Optional server value in `initServer.sqf`; freezes catalogue refreshes after setup. |
| `_useExample` | Boolean | `false` | `MissionConfig/economyConfig.sqf`; use `true` only to load the shipped example catalogue. |

The optional `initServer.sqf` rows are commented out in the shipped mission. “Unset” means
WMP does not apply that choice for you; it is not a fourth preset. A composition can make
the enable/preset choice instead. Do not use a composition and a competing hand-written
preset unless you intend one to override the other.

## Quick configuration in `initServer.sqf`

A commented block in `initServer.sqf` exposes the quick options:

```sqf
// A bundled preset:
missionNamespace setVariable ["Waldo_Economy_Preset", "MEDIUM", true];   // LOW | MEDIUM | HIGH
missionNamespace setVariable ["Waldo_Economy_PresetSides", [["WEST","NATO"],["EAST","CSAT"],["GUER","AAF"]], true];

// ...or a full configuration exported from the Zeus "Export" tool (wins over a preset):
missionNamespace setVariable ["Waldo_Economy_ConfigString", "PASTE_EXPORT_STRING_HERE", true];

// Optional perf toggle (freeze config refreshes once you finish configuring):
missionNamespace setVariable ["Waldo_Economy_CommitmentMode", true, true];
```

Preset complexities: **LOW** (a single resource + research) → **HIGH** (a full Factorio-style economy). Faction catalogue keys for `Waldo_Economy_PresetSides`: `NATO`, `CSAT`, `AAF`, `SYNDIKAT`, `GENERIC`.

## Settings: full hand-authoring (`MissionConfig\economyConfig.sqf`)

For complete control, edit **`MissionConfig\economyConfig.sqf`**. WMP registers it as `Waldo_fnc_EcoMakerSetup` and runs it once on the server after a preset or imported config string. Set `_useExample = true;` to try its worked example, then copy only the rows your mission needs.

Define catalogs and place world objects with the server-side helpers:

| Public call | Argument types, in order | Return / effect |
| --- | --- | --- |
| `Waldo_fnc_EcoResource_addResourceType` | Resource name String, hex colour String, icon path String, storage cap Number (`-1` for unlimited) | Adds a resource type to the server-owned catalogue; no documented ID/object return. |
| `Waldo_fnc_EcoResearch_setResearchCatalog` | One Array containing research rows `[name String, description String, costs Array, requirements Array, timeSeconds Number]` | Replaces the research catalogue; no return value. |
| `Waldo_fnc_EcoBuild_setBuildCatalog` | One Array containing building rows; see the complete row example below and [Build System](Waldos-Economy-Systems-Build-System) | Replaces the building catalogue; no return value. |
| `Waldo_fnc_EcoBuy_setPurchaseCatalog` | One Array containing purchase rows; see the complete row example below and [Buy System](Waldos-Economy-Systems-Buy-System) | Replaces the purchase catalogue; no return value. |
| `Waldo_fnc_EcoResource_createResourceZone` | Position Array, name String, radius Number, resource deposits Array, side ID String, interval seconds Number | Creates a resource zone; returns its ID String on the server. A client call forwards the request and has no immediate ID. |
| `Waldo_fnc_EcoResearch_spawnResearchCenter` | Position Array | Returns the spawned Object on the server. A forwarded client call returns `objNull`. |

These are server-side setup calls, not object Init snippets. Their exact row shapes are
shown in `MissionConfig/economyConfig.sqf`; the subsystem pages explain the gameplay
rules. The resulting state is published to joining players. The catalogue helpers do
not provide an object or ID for later use; check the published catalogue instead.

```sqf
// Resources: [name, "#hexColour", "iconPath", storageCap]  (-1 = unlimited)
["Supplies", "#D4C15A", call Waldo_fnc_EcoResource_getDefaultResourceIcon, -1] call Waldo_fnc_EcoResource_addResourceType;

// Research / Buildings / Purchases: pass an array of entries
[[ ["Logistics I", "Basic supply handling.", [["Supplies", 10]], [], 60] ]] call Waldo_fnc_EcoResearch_setResearchCatalog;
[[ ["Generator", "Produces fuel.", [["Supplies", 15]], [], 90, "", "", false, "Land_PowerGenerator_F", "Fuel", 2, 20] ]] call Waldo_fnc_EcoBuild_setBuildCatalog;
[[ ["Transport Truck", "A cargo truck.", [["Supplies", 10]], ["Vehicle Depot"], "B_Truck_01_transport_F", "Ground", "EVERYONE"] ]] call Waldo_fnc_EcoBuy_setPurchaseCatalog;

// Place world objects (e.g. at a marker):
[getMarkerPos "eco_zone_1", "Supply Field", 30, [["Supplies", 2, 500]], "NONE", 30] call Waldo_fnc_EcoResource_createResourceZone;
[getMarkerPos "eco_research_1"] call Waldo_fnc_EcoResearch_spawnResearchCenter;
```

**Build it in Zeus, then bake it into the mission:** use the normal Resource, Research, Construction and Purchasing Zeus modules to configure and place the system visually. Then open **Configuration: Build Mission Setup**, select the systems to include, and press **BUILD + COPY**. The generated, pre-filled public setup calls are copied to the clipboard immediately. Paste them into `MissionConfig\economyConfig.sqf`; no array editing or manual argument reconstruction is required.

The generated recipe preserves the authoring result: resource definitions, initial side balances and marker visibility; research, construction and purchasing catalogues; and the current resource zones, uncollected resource crates, research centres, construction sources, completed economy buildings, delivery points and purchase terminals. Calls are emitted in dependency order so the catalogues exist before their placed equipment is created.

Export from a clean authoring session before normal play begins. The exporter records the current
world positions, directions, classes and economy tags; it is not intended to turn an in-progress
campaign save into mission source. Keep `Waldo_Economy_Enable` set to `true` in
`MissionConfig\missionSystemsConfig.sqf`.

Use **Config Copy** only when you need the older portable catalogue string for `Waldo_Economy_ConfigString` in `initServer.sqf` or for **Import**. Older exported configuration strings remain compatible.

The builder explains the copy-and-paste workflow inside the display. It owns mouse and keyboard focus while open and does not dismiss unrelated WMP notifications.

## Designate editor-placed objects

Arma can only add true Eden "Systems" modules from a **loaded addon**, and WMP is a mission framework, not a mod. Instead, place a normal object in Eden and turn it into an economy object from its **init field**:

| Place this object | Put this in its init field |
|---|---|
| `Land_Research_HQ_F` | `[this] call Waldo_fnc_EcoResearch_registerCenter;` |
| `Land_Laptop_unfolded_F` | `[this] call Waldo_fnc_EcoBuy_registerTerminal;` |
| any vehicle | `[this] call Waldo_fnc_EcoBuild_registerConstructionVehicle;` |

## Order of application

`Waldo_fnc_EcoInit` → `Waldo_fnc_EcoCore_applyMakerConfig` runs, in order: a config string (if set) **or** a preset, then commitment mode, then `MissionConfig\economyConfig.sqf`. So you can build on a preset or define everything from scratch. It only runs on the server authority, exactly once.

## If the economy does not start

Check the suite's enable setting and whether you selected a preset or supplied a valid authored configuration. Use [Mission Diagnostics](Mission-Diagnostics) to inspect server initialization and catalogue errors. A Zeus authoring session changes the live mission only until you export and paste its setup into the mission configuration.

## See also

- [Economy Systems](Waldos-Economy-Systems)
- [Feature Configuration Files](Feature-Configuration-Files)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)

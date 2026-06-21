_Associated Files: `initServer.sqf`, `MissionScripts\MissionFlowAndUi\runDiagnostics.sqf`, `Waldo_fnc_RunDiagnostics`_

# Mission Diagnostics

Mission Diagnostics is a server-side configuration sanity check that runs once at mission start (just after the loadout scan) and reports the most common WaldosMissionPack misconfigurations. It is **read-only** — it never changes mission state and never throws — so it is safe to leave on while building, and easy to silence for a shipping mission.

Output goes to the **RPT log**, with every line prefixed `[WMP DIAG]`. Any **warning** is also echoed to admins/host on screen via `systemChat`, so you see problems without digging through the log. Informational lines (e.g. how many items each side's loadout scrape produced) stay in the RPT to avoid spam.

## What it checks

| Check | Warns when |
|---|---|
| **Required mods** | CBA_A3 or ACE3 are not detected. |
| **Per-side loadout scrape** | A side has playable slots but its scraped loadout is empty — the classic symptom of vanilla loadouts (not edited with ACE Arsenal) or a **binarized** `mission.sqm`. Also warns if there are no playable units at all. |
| **Crate classnames** | `Logi_SupplyBoxClass` / `Logi_MedicalBoxClass` is not a valid `CfgVehicles` class. |
| **Paradrop thresholds** | Static-line min altitude is not below max altitude, or max speed is not greater than 0. |
| **Parachute classes** | `WALDO_STATIC_STATICCHUTE` / `WALDO_PARA_HALOCHUTE` is not a valid `CfgVehicles` class (usually a missing mod). |
| **ACRE2 LR channels** | Long-range channel arrays are empty (informational only, and only when ACRE2 is loaded). |

It finishes with a one-line summary of how many warnings were raised.

## Enabling / disabling

It is **on by default**. A documented block in `initServer.sqf` controls it:

```sqf
// Set to false to silence diagnostics for a shipping mission:
missionNamespace setVariable ["Waldo_RunDiagnostics", true, true];
```

Leave it on during development to catch problems early; set it to `false` before you ship if you'd rather keep the RPT clean.

## Reading the output

Open your `*.rpt` file (or watch the on-screen admin messages) and search for `[WMP DIAG]`. For example:

```
[WMP DIAG] INFO: Running WaldosMissionPack configuration diagnostics...
[WMP DIAG] INFO: BLUFOR loadout pool: 142 unique items.
[WMP DIAG] WARN: OPFOR has playable units but its scraped loadout is empty. Edit unit loadouts with ACE Arsenal and disable mission binarization.
[WMP DIAG] 1 configuration warning(s) raised - see RPT log for details.
```

The function also **returns** the number of warnings raised, if you want to call it yourself:

```sqf
private _warnings = [] call Waldo_fnc_RunDiagnostics;
```

## See also

* [Logistics System, Starter Crates And Quartermaster](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Logistics-System,-Starter-Crates-And-Quartermaster) — the loadout scrape these checks validate
* [Mission Configuration Reference](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Mission-Configuration-Reference) — all `initServer.sqf` fields
* [Vehicle Actions & Paradrop](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Vehicle-Actions-&-Paradrop) — the paradrop thresholds these checks validate

# Safestart

> **Use this page when:** you need to protect mission preparation, run a countdown, go live, or diagnose stuck protection.

_Associated Files: `initServer.sqf`, `MissionScripts\MissionFlowAndUi\safeStart.sqf`, `safeStartTimer.sqf`, `safeStartApply.sqf`, `Waldo_fnc_SafeStart`, `Waldo_fnc_SafeStartTimer`_


![SafeStart countdown](images/mission-flow/safestart-countdown.png)

Safestart protects players while they load in and sort their kit. Missions start live by default, but Zeus can activate Safestart at any point. Unlike [ENDEX](ENDEX-Script-&-Custom-End-Screen), Safestart can be lifted when play begins.

While Safestart is active:
* ACE places weapons on safe. Shots, thrown grenades, launcher rounds, underbarrel rounds and crewed vehicle weapon rounds are deleted. Firing shows a red **"Hold Fire!"** prompt.
* Players take and deal **no damage**.
* If the mission maker enables confinement, players are pulled back when they leave the safe zone.
* An on-screen **banner** is shown, with a live go-live countdown when a timer is running.
* **JIP and respawning players are re-frozen automatically**, so latecomers can't skip it.

The freeze runs on its own variables, so it never clashes with ENDEX.

## Quick setup: starting state

Safestart is available automatically but starts **inactive**. To begin a mission under protection, open `MissionConfig\missionSystemsConfig.sqf` and change the existing `Waldo_SafeStart_AutoStart` row from `false` to `true`. To use confinement, change the existing `Waldo_SafeStart_Confine` row too. Do not add a second copy of either setting to an init file.

```sqf
["Waldo_SafeStart_Confine", true, true],
["Waldo_SafeStart_Radius", 150, false],
["Waldo_SafeStart_ZoneMarker", "", false],
["Waldo_SafeStart_AutoStart", true, true]
```

| Variable | Type | Shipped default | Purpose |
|---|---|---|---|
| `Waldo_SafeStart_AutoStart` | Boolean | `false` | `false` starts live while retaining all Zeus controls; `true` begins protected. |
| `Waldo_SafeStart_Confine` | Boolean | `false` | Set `true` to pull players back into the configured area while protection is active. |
| `Waldo_SafeStart_Radius` | Number, metres | `150` | Confinement radius around each player's start position when no zone marker is set. |
| `Waldo_SafeStart_ZoneMarker` | Marker-name string | `""` | Blank uses the per-player radius; an existing Eden area marker name uses one shared zone, including that marker's size. This is a **string**, not an Object. |
| `Waldo_SafeStart_GoLiveHintDuration` | Number, seconds | `12` (script fallback) | Time the go-live explanation stays visible. This is not a shipped config row; advanced missions can set it on the server before the notice. |

## Script calls: going live

The API is **server-authoritative**. A client call forwards to the server.

```sqf
[true]  call Waldo_fnc_SafeStart;        // activate the freeze
[false] call Waldo_fnc_SafeStart;        // go live (admin overrule; also cancels any countdown)
[300]   call Waldo_fnc_SafeStartTimer;   // go live automatically in 300 seconds (banner shows the clock)
```

| Call | Position | Type | Default | Meaning |
| --- | --- | --- | --- | --- |
| `Waldo_fnc_SafeStart` | `0: enable` | Boolean | `true` | `true` starts protection; `false` ends it and cancels the countdown. |
| `Waldo_fnc_SafeStart` | `1: reason` | String | `"MANUAL"` | Reason recorded with the state change. Normal mission calls can omit it. |
| `Waldo_fnc_SafeStartTimer` | `0: seconds` | Number, seconds | `300` | Delay until go-live. Zero or less goes live now. A new timer replaces an earlier deadline. |

Both calls return nothing. A client call only forwards the request; read the published state if a later step depends on completion. `initServer.sqf` calls SafeStart only when `AutoStart` is on. The SafeStart ZEN controls and timer use the same authority path. Players joining during protection receive the current state and countdown.

`Waldo_fnc_SafeStartTimer` makes sure Safestart is active, then publishes the go-live time so every player's banner shows a live countdown, and lifts the freeze automatically when it expires. Calling it again restarts/extends the timer. An admin can overrule a running countdown at any time with `[false] call Waldo_fnc_SafeStart`.

SafeStart and ENDEX own separate fire handlers, damage state and ACE safety changes. If ENDEX is active when the countdown finishes, the SafeStart restriction is removed but ENDEX remains in force; the transition panel says so explicitly. Use `[] call Waldo_fnc_ENDEXReset` only when the exercise should resume.

The active banner explicitly says when no countdown exists, so a manual hold is
not mistaken for a stuck timer. When Safestart is lifted, the longer go-live
notice explains that weapon, damage and confinement protections have ended and
whether the change was manual or timer-driven.

Only one compact SafeStart panel exists at a time. Starting or changing a countdown updates the
existing panel rather than opening another one. The panel waits for the mission title sequence to
finish, uses safe-zone padding, and displays configured seconds as `MM:SS` for players.

Each player can open **Self Interactions > WMP Interface > Acknowledge SafeStart** while protection
is active. This only hides that player's panel; weapons, damage protection, confinement, the timer
and every other player's display remain unchanged. Acknowledging the ordinary waiting phase hides
the panel until a countdown begins. The countdown is a new phase and makes it visible again, so the
player sees that go-live is approaching. They may acknowledge it a second time to hide it until
go-live. The acknowledgement is cleared when SafeStart ends and never carries into a later
activation.

## If safe start does not end: diagnostics

```sqf
private _report = [] call Waldo_fnc_SafeStartGetDiagnostics;
```

The report identifies whether the code is loaded, whether SafeStart is active, its published go-live time, the local protection loop, and the current HUD state. The same checks appear in `[] call Waldo_fnc_RunDiagnostics` under mission flow.

## Zeus usage

Three modules are registered under **WMP Mission Flow** in the Zeus menu. They remain available even
though Safestart starts inactive:

| Module | Action |
|---|---|
| **SafeStart: Enable Protection** | Freezes the mission (`[true] call Waldo_fnc_SafeStart`). Use this to begin a hold during play. |
| **SafeStart: Go Live Now** | Lifts the freeze and cancels any countdown. |
| **SafeStart: Start Go-Live Timer** | Activates protection if needed, prompts for seconds, then lifts it automatically. Player HUDs display `MM:SS`. |

[Waldos Mission Pack Zeus Modules](Waldos-Mission-Pack-Zeus-Modules) are covered separately.

## Examples

```sqf
// Hold the mission, then auto go-live 5 minutes later from a trigger:
[300] call Waldo_fnc_SafeStartTimer;

// To start protected or use a shared area, edit the existing rows in
// MissionConfig/missionSystemsConfig.sqf before the mission starts.
// For a shared area, place an Eden marker named startzone and set
// Waldo_SafeStart_Confine to true and Waldo_SafeStart_ZoneMarker to "startzone".
```

## See also

* [ENDEX Script & Custom End Screen](ENDEX-Script-&-Custom-End-Screen): the matching mission-end freeze
* [Mission Configuration Reference](Mission-Configuration-Reference) - where the mission settings are loaded
* [Waldos Mission Pack Zeus Modules](Waldos-Mission-Pack-Zeus-Modules)
* [Zeus END-Key Kill Restore](Zeus-End-Key-Kill-Restore): additive selected-object fallback for the normal Zeus END action

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)

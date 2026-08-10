# Headless Client Support

> **Use this page when:** you're running (or planning to run) one or more Arma 3 headless clients alongside a WMP mission and want AI groups to distribute across them automatically.

_Associated Files: `MissionScripts\Headless\headlessDetectLocal.sqf`, `headlessRegisterClient.sqf`, `headlessRebalance.sqf`, `headlessMigrateGroup.sqf`, `headlessReassignOnDisconnect.sqf`, `headlessGetDiagnostics.sqf`, `init.sqf`, `initServer.sqf`, `Waldo_fnc_HeadlessDetectLocal`_

## Overview

WMP ships native, server-authoritative headless-client (HC) support: connect a headless client to a
hosted mission and it self-registers with the server, which then distributes eligible AI groups to
it automatically. There is nothing to configure in `MissionConfig` and nothing to place in Eden -
this is infrastructure-level support that every mission gets for free the moment an HC connects.

This replaces the legacy, third-party `MissionScripts\ThirdPartyScripts\WerthlesHeadless.sqf`
("Werthles' Headless Kit" v2.3), which is kept in the repository, unmodified and disabled by default,
for reference only. It has known deviations from WMP's own model (a non-standard HC detection test,
a name-string exclusion list unaware of WMP-owned control groups, and no integration with WMP's
diagnostics or JIP snapshot handshake) and should not be re-enabled.

## How it works

1. **Detection.** Every machine calls `Waldo_fnc_HeadlessDetectLocal` from `init.sqf`, gated behind
   WMP's ordered feature-runtime snapshot handshake (the same one AI rebalance and improved
   helicopter landing use). A headless client is identified with the standard, version-stable test
   `!isDedicated && !hasInterface`. The server and every real player are no-ops here.
2. **Registration.** A detected headless client asks the server to register it
   (`Waldo_fnc_HeadlessRegisterClient`), which verifies the request came from a genuine remote
   caller (never a spoofed local id) and is not already a connected player, then adds it to
   `Waldo_Headless_Clients` and immediately runs a rebalance pass.
3. **Rebalancing.** `Waldo_fnc_HeadlessRebalance` walks every group in the mission and migrates each
   *eligible* one to whichever connected headless client currently has the fewest assigned groups.
   Every actual `setGroupOwner` call funnels through `Waldo_fnc_HeadlessMigrateGroup`, so
   `Waldo_Headless_ManagedGroups` never drifts from reality.
4. **Disconnect recovery.** `initServer.sqf` installs a `HandleDisconnect` mission event handler
   (`Waldo_fnc_HeadlessReassignOnDisconnect`). When a headless client disconnects, its groups return
   to the server and a rebalance pass immediately offers them to any other connected headless
   client. This is event-driven - there is no polling loop watching for disconnects.

## Eligibility

A group is migrated only when **all** of the following hold. Anything excluded is recorded (with a
reason) in `Waldo_Headless_ExcludedGroups`, refreshed on every rebalance pass:

| Excluded when... | Reason logged |
|---|---|
| The group is empty | `empty` |
| Any member (including the leader) is a human player | `player-led` |
| The group variable `Waldo_Headless_ExcludeGroup` is `true` | `opted-out` |
| The group's side is `sideLogic` (curator helpers/ZEN module logic) | `curator-logic` |
| The group currently crews a registered Airborne Gunship aircraft (`Waldo_Gunship_Registry`) | `gunship-crew` |
| The group is not currently local to the server | `not-server-local` |
| The group is already assigned to a still-connected headless client | `already-managed` |

**Opting a group out.** Any WMP subsystem (or mission script) that owns AI it never wants migrated
can set the group variable directly - no code change to the headless system is required:

```sqf
_group setVariable ["Waldo_Headless_ExcludeGroup", true];
```

## Why locality-sensitive features don't need HC-specific changes

WMP's other AI-driven systems already assume group ownership can move, using two mechanisms this
rework deliberately reuses rather than duplicates:

- **Redispatch** - a function checks `local _group`; if not local, it looks up the current
  `groupOwner _group` and `remoteExecCall`s itself there. Used by Dynamic AA
  (`Waldo_fnc_DynamicAASetGroupState`), every "Local" function in `Logistics\TransportServices\`, and
  the AI convoy ZEN module.
- **Adoption** - a per-unit engine `Local` event handler reapplies state whenever that unit's own
  locality changes, for any reason including HC migration. Used by AI rebalance
  (`Waldo_AI_LocalHandlerInstalled`) and improved helicopter landing
  (`Waldo_ImprovedHelicopterLanding_TrackedLocal`).

The one system found *not* to redispatch correctly, Dynamic AO's patrol-waypoint setup
(`Waldo_fnc_DynamicAOAddPatrolWaypoints`), was fixed to match the same redispatch pattern as part of
this rework.

## Diagnostics

`Waldo_fnc_HeadlessGetDiagnostics` feeds into `Waldo_fnc_RunDiagnostics` under area `headless`:

| Check | States |
|---|---|
| `headless-clients` | `UNCONFIGURED` (none connected) / `ACTIVE` |
| `headless-managed-groups` | `LOADED` / `ACTIVE` (at least one group assigned) |
| `headless-excluded-groups` | `LOADED`, always reported; see `Waldo_Headless_ExcludedGroups` for reasons |
| `headless-failed-transfers` | `LOADED` / `ERROR` (any entry in `Waldo_Headless_FailedTransfers`) |
| `headless-ownership-consistency` | `LOADED` / `ERROR` (registry vs. actual `groupOwner` mismatch, or an orphaned entry for a disconnected client not yet reconciled) |

## Known limitation / what still needs live testing

This system was implemented and code-reviewed without access to a live Arma 3 engine or a connected
headless-client process. Before relying on it in a live mission, run the full manual matrix once
against your actual mod set: Dynamic AO, Dynamic AA, transports, gunships, paradrops and improved
helicopter landing, each with no HC, one HC, multiple HCs, an HC disconnect/reconnect cycle, and JIP
players joining mid-mission. See `FEATURE_LOG.md`'s "Headless-client compatibility rework" entry and
`releaseVerificationAndDeployment/fullArmaAudit/PROCESS.md` for how to stage this against the audit
mission.

## See also

- [Mission Diagnostics](Mission-Diagnostics) - the general diagnostics report this feature feeds into.
- [Optional Third-Party Scripts (Player Markers)](Third-Party-Scripts-Headless-Client-And-Player-Markers) - the legacy, superseded WerthlesHeadless.sqf entry point.
- `FEATURE_LOG.md` in the repository root - implementation history and outstanding acceptance testing.

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)

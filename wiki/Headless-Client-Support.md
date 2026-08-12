# Headless Client Support

> **Use this page when:** you're running (or planning to run) one or more Arma 3 headless clients alongside a WMP mission and want AI groups to distribute across them automatically.

_Associated Files: `MissionConfig\headlessConfig.sqf`, `MissionScripts\Headless\headlessDetectLocal.sqf`, `headlessRegisterClient.sqf`, `headlessRebalance.sqf`, `headlessMigrationWorker.sqf`, `headlessMigrateGroup.sqf`, `headlessReassignOnDisconnect.sqf`, `headlessGetDiagnostics.sqf`, `init.sqf`, `initServer.sqf`, `Waldo_fnc_HeadlessDetectLocal`_

## Overview

WMP ships native, server-authoritative headless-client (HC) support: connect a headless client to a
hosted mission with the feature turned on and it self-registers with the server, which then
distributes eligible AI groups to it automatically.

This replaces the legacy, third-party `MissionScripts\ThirdPartyScripts\WerthlesHeadless.sqf`
("Werthles' Headless Kit" v2.3), which is kept in the repository, unmodified and disabled by default,
for reference only. It has known deviations from WMP's own model (a non-standard HC detection test,
a name-string exclusion list unaware of WMP-owned control groups, and no integration with WMP's
diagnostics or JIP snapshot handshake) and should not be re-enabled.

## Off by default

`Waldo_Headless_Enable` in `MissionConfig\headlessConfig.sqf` defaults to `false`. This system has
not yet been verified against a live Arma 3 engine or a connected headless client (see "Known
limitation" below) - connecting a headless client to a mission that has not explicitly turned this on
has no effect at all. Both `Waldo_fnc_HeadlessDetectLocal` (the client-side check) and
`Waldo_fnc_HeadlessRegisterClient` (the actual server-side authority boundary) independently refuse
to do anything while it's false, so there is no partial/accidental activation path.

```sqf
// MissionConfig\headlessConfig.sqf
["Waldo_Headless_Enable", false],              // MISSION MAKER: master switch. Turn on only after
                                                // running the live HC test matrix below for your mod set.
["Waldo_Headless_StartDelaySeconds", 30],      // ADVANCED: grace period before any migration begins.
["Waldo_Headless_MinGroupAgeSeconds", 10],     // ADVANCED: per-group settle time before eligibility.
["Waldo_Headless_MigrationPaceSeconds", 3]     // ADVANCED: pause between each queued migration.
```

## Eden setup - one required step, Arma-level not WMP-specific

A headless client connects into a mission slot the same way a player does, so the mission needs
somewhere for it to go. Place one **Headless Client** Virtual Entity (3DEN's Systems/Logic entity
category) per headless client you plan to connect, and set each one **Playable**. This is ordinary
Arma 3 slot plumbing, not a WMP configuration step, and applies regardless of which script manages
the AI afterwards. Some third-party headless-client tooling additionally requires a specific
role/variable naming convention on these slots (for example, matching pairs like `hc1`/`hc1`) so its
own module can identify them - **WMP's native system has no such requirement**: it identifies a
headless client purely at runtime, by `!isDedicated && !hasInterface`, so the slot can be named
anything.

`WMP_Compositions/[WMP]Headless_Client_Setup_Example` drops in five named, Playable Headless Client
Virtual Entities (`HC_1`-`HC_5`) at once so you don't have to place and flag each one by hand - delete
whichever you don't need. The names are for your own reference only; WMP's detection doesn't care
what a slot is called.

Actually connecting the headless-client process to your hosted/dedicated server - allow-listing its
IP in `server.cfg`'s `headlessClients[]`, and launching the HC process itself with
`-client -connect=<serverIP> -password=<password>` - is ordinary Arma 3 server hosting, outside WMP's
scope; consult your server host or Bohemia's own headless-client documentation for that step.

**Headless clients count toward `description.ext`'s `maxPlayers`.** A connecting HC with an
allow-listed IP is meant to auto-fill the first free Headless Client slot with no manual role
selection - but if `maxPlayers` was only sized for your human player count, adding several HCs on top
of it can silently prevent them from ever being assigned a slot, even though the underlying network
connection itself succeeds (still visible in the RPT/server log). Size `maxPlayers` for human players
**plus** every headless client slot you intend to fill.

## How it works

1. **Detection.** Every machine calls `Waldo_fnc_HeadlessDetectLocal` from `init.sqf`, gated behind
   WMP's ordered feature-runtime snapshot handshake (the same one AI rebalance and improved
   helicopter landing use). A headless client is identified with the standard, version-stable test
   `!isDedicated && !hasInterface`. The server and every real player are no-ops here. If
   `Waldo_Headless_Enable` is false, detection still runs (harmless) but the registration request
   below is never sent.
2. **Registration.** A detected headless client asks the server to register it
   (`Waldo_fnc_HeadlessRegisterClient`), which verifies the request came from a genuine remote
   caller (never a spoofed local id) and is not already a connected player, then adds it to
   `Waldo_Headless_Clients` and immediately runs a rebalance pass.
3. **Rebalancing.** `Waldo_fnc_HeadlessRebalance` walks every group in the mission, works out which
   *eligible* ones should move to whichever connected headless client currently has the fewest
   assigned/queued groups, and queues them in `Waldo_Headless_MigrationQueue`.
4. **Paced migration.** `Waldo_fnc_HeadlessMigrationWorker` drains that queue one group at a time,
   `Waldo_Headless_MigrationPaceSeconds` (default 3s) apart, calling
   `Waldo_fnc_HeadlessMigrateGroup` - the single funnel every actual `setGroupOwner` call in this
   rework goes through, so `Waldo_Headless_ManagedGroups` never drifts from reality. Migrating many
   groups back-to-back in the same frame is a known source of a server hitch on a busy mission; this
   is the same reason established headless-client community tooling paces its own transfers instead
   of moving everything the instant it becomes eligible.
5. **Disconnect recovery.** `initServer.sqf` installs a `HandleDisconnect` mission event handler
   (`Waldo_fnc_HeadlessReassignOnDisconnect`). When a headless client disconnects, its groups return
   to the server immediately (not through the paced queue - losing AI ownership briefly is worse than
   a small hitch here), and a rebalance pass immediately offers them to any other connected headless
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
| WMP has not seen this group for `Waldo_Headless_MinGroupAgeSeconds` yet (default 10s) | `too-new` |
| The group is not currently local to the server | `not-server-local` |
| The group is already assigned to (or already queued for) a still-connected headless client | `already-managed` |

**Why a minimum group age exists.** A group migrated the instant it exists can outrun whatever is
still in the middle of populating or configuring it - a custom AI mod's own setup pass, a mission
trigger, WMP's own Dynamic AO. Giving every group a short settle time before it becomes eligible is
the same mitigation established headless-client tooling documents for exactly this class of
interference: *"other scripts that change how units spawn or their behaviour are likely to interfere
... [migration] could break some scripts where local commands are issued for units that are no
longer local."* The `too-new` window and the mission-wide start delay below both exist because of
that documented interaction, not a hypothetical one.

**Mission-wide start delay.** `Waldo_fnc_HeadlessRebalance` does nothing at all until
`Waldo_Headless_StartDelaySeconds` (default 30s) of mission time have passed, even if a headless
client registers earlier - giving mission-wide AI-spawning infrastructure a moment to get through its
own initial setup pass before anything starts moving. Both this and the per-group settle time are
edited in `MissionConfig\headlessConfig.sqf` alongside `Waldo_Headless_Enable`, the same place every
other WMP feature's tunables live - if your mission's AI setup needs more (or less) time:

```sqf
// MissionConfig\headlessConfig.sqf
["Waldo_Headless_StartDelaySeconds", 60],
["Waldo_Headless_MinGroupAgeSeconds", 20],
["Waldo_Headless_MigrationPaceSeconds", 5]
```

**Opting a group out.** Any WMP subsystem (or mission script) that owns AI it never wants migrated
can set the group variable directly - no code change to the headless system is required. The check
only ever runs on the server, so the flag must actually be visible there: an object's own Eden init
field already executes on every machine including the server, so setting it there needs no broadcast:

```sqf
// From a group leader's Eden init field (runs on every machine, including the server - no
// broadcast flag needed):
_group setVariable ["Waldo_Headless_ExcludeGroup", true];
```

A script that might run **only** on a client (a ZEN custom module's own code, for example, executes
on the curator's client, never the server) must broadcast the flag explicitly or the server will
never see it and the group will migrate anyway:

```sqf
_group setVariable ["Waldo_Headless_ExcludeGroup", true, true];
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

## Third-party AI mod compatibility (VCOM AI, LAMBS, ASR AI3, ...)

The legacy `WerthlesHeadless.sqf`'s best-known failure mode was AI going unresponsive after a
migration - most often because a third-party AI-behaviour mod installs its own per-unit logic once,
from a one-shot unit/group init event, and assumes it keeps running on that same machine forever
rather than continuously re-checking `local`. WMP cannot fix a mod's own locality handling from the
outside, but every successful migration broadcasts a CBA global event so a mission's own
compatibility layer can react on whichever machine just became responsible:

```sqf
// Anywhere that runs on every machine (e.g. init.sqf):
["Waldo_Headless_GroupMigrated", {
    params ["_group", "_previousOwner", "_newOwner"];
    if (local _group) then {
        // Re-run whatever your AI mod needs to (re-)adopt this group's units on this machine,
        // e.g. its own per-unit setup/init function.
        {[_x] call SOME_MOD_fnc_reinitialiseUnit;} forEach units _group;
    };
}] call CBA_fnc_addEventHandler;
```

This is a mitigation hook, not a guarantee - if your mod set is known to misbehave under headless
clients, treat that as a strong reason to set `Waldo_Headless_ExcludeGroup` on the affected groups
rather than relying on a compatibility listener alone.

## Trigger/waypoint synchronisation is not preserved across a migration

This is an Arma engine limitation, not a WMP gap: `setGroupOwner` does not reliably carry over a
waypoint's synchronisation to a trigger or another waypoint. If a group has a waypoint synced to a
trigger, insert a non-overlapping spacer waypoint immediately before that synced one - the spacer
absorbs the migration without disturbing the sync. This is the same documented workaround for the
legacy tooling this system replaces (which attempted its own capture/reapply of sync state in script
and still needed it), so treat it as required practice for any mission using trigger-synced waypoints
on AI groups that might migrate, not an optional precaution.

## Diagnostics

`Waldo_fnc_HeadlessGetDiagnostics` feeds into `Waldo_fnc_RunDiagnostics` under area `headless`.
While `Waldo_Headless_Enable` is false, it reports a single `headless-enable: DISABLED` check and
nothing else; the rows below only apply once enabled:

| Check | States |
|---|---|
| `headless-clients` | `UNCONFIGURED` (none connected) / `ACTIVE` |
| `headless-managed-groups` | `LOADED` / `ACTIVE` (at least one group assigned) |
| `headless-excluded-groups` | `LOADED`, always reported; see `Waldo_Headless_ExcludedGroups` for reasons |
| `headless-failed-transfers` | `LOADED` / `ERROR` (any entry in `Waldo_Headless_FailedTransfers`) |
| `headless-ownership-consistency` | `LOADED` / `ERROR` (registry vs. actual `groupOwner` mismatch, or an orphaned entry for a disconnected client not yet reconciled) |
| `headless-migration-queue` | `LOADED` / `ACTIVE` (queue length, worker running, and the current start-delay/min-age/pace settings) |

## Known limitation / what still needs live testing

This system was implemented and code-reviewed without access to a live Arma 3 engine or a connected
headless-client process. Before relying on it in a live mission, run the full manual matrix once
against your actual mod set: Dynamic AO, Dynamic AA, transports, gunships, paradrops and improved
helicopter landing, each with no HC, one HC, multiple HCs, an HC disconnect/reconnect cycle, and JIP
players joining mid-mission. See `FEATURE_LOG.md`'s "Headless-client compatibility rework" entry and
`releaseVerificationAndDeployment/fullArmaAudit/PROCESS.md` for how to stage this against the audit
mission.

**Priority-one check: vehicle-crewed AI groups.** A crewed vehicle's own locality is normally carried
by the engine along with its crew's group locality, but this is Arma's own behaviour, not something
WMP controls or can verify without a live engine, and it is the single most-reported real-world cause
of "AI went unresponsive after moving to a headless client" reports in the wider community
(independent of `WerthlesHeadless.sqf` specifically) - a vehicle whose locality does not follow its
AI driver/gunner produces exactly that symptom. Test AI vehicle patrols and convoys under a headless
client before anything else in the matrix above.

## See also

- [Mission Diagnostics](Mission-Diagnostics) - the general diagnostics report this feature feeds into.
- [Optional Third-Party Scripts (Player Markers)](Third-Party-Scripts-Headless-Client-And-Player-Markers) - the legacy, superseded WerthlesHeadless.sqf entry point.
- `FEATURE_LOG.md` in the repository root - implementation history and outstanding acceptance testing.

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)

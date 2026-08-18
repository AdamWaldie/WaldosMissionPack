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

`Waldo_Headless_Enable` in `MissionConfig\headlessConfig.sqf` defaults to `false`. Dedicated-server
testing has verified registration, distribution, manual handoff, debug display and disconnect
handling. It remains opt-in because Headless Client behaviour depends heavily on the mission's AI
mods and locality-sensitive scripts. Connecting a headless client to a mission that has not
explicitly turned this on has no effect. Both `Waldo_fnc_HeadlessDetectLocal` (the client-side check) and
`Waldo_fnc_HeadlessRegisterClient` (the actual server-side authority boundary) independently refuse
to do anything while it's false, so there is no partial/accidental activation path.

```sqf
// MissionConfig\headlessConfig.sqf
["Waldo_Headless_Enable", false],              // MISSION MAKER: master switch. Enable after testing
                                                // your mission's actual AI and mod set.
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
Virtual Entities (`HC_1`-`HC_5`) at once, each with `forceHeadlessClient` set, so you don't have to
place and flag each one by hand - delete whichever you don't need. The names are for your own
reference only; WMP's detection doesn't care what a slot is called.

Actually connecting the headless-client process to your hosted/dedicated server - allow-listing its
IP in `server.cfg`'s `headlessClients[]`, and launching the HC process itself with
`-client -connect=<serverIP> -password=<password>` - is ordinary Arma 3 server hosting, outside WMP's
scope. The **Headless Client Kit** is a separate download (its own release artifact, `WMP_HC-<version>.zip`,
not part of the main pack) with annotated examples for exactly this step - a `server.cfg` snippet,
a launch script for connecting one HC to a server you already have running, and a script that stands
up a throwaway local server plus HC(s) so you can rehearse the whole flow before touching a real
host. Otherwise, consult your server host or Bohemia's own headless-client documentation.

**Headless clients count toward `description.ext`'s `maxPlayers`.** A connecting HC with an
allow-listed IP is meant to auto-fill the first free Headless Client slot with no manual role
selection - but if `maxPlayers` was only sized for your human player count, adding several HCs on top
of it can silently prevent them from ever being assigned a slot, even though the underlying network
connection itself succeeds (still visible in the RPT/server log). Size `maxPlayers` for human players
**plus** every headless client slot you intend to fill.

### Connected but not filling a slot

If the server log shows a headless client's connection succeeding (look for the trusted/local
signature - very high bandwidth and `ping=0`, matching a `localClient[]` entry) but it never appears
occupying one of the placed slots:

- **There is no admin control to manually assign it.** Slot assignment for a genuine, IP-authorized
  `-client` connection is handled entirely and automatically by the Arma engine at the moment of
  connection - an admin's "Virtual" category in the player list only shows headless clients *after*
  they have already been auto-assigned; it is not a tool for assigning an unslotted one. If auto-slotting
  didn't happen, the fix is on the connection/mission side (see the checks above and below), not
  something an admin can force from in-game.
- Check `maxPlayers` first (above).
- Confirm the connecting IP matches `headlessClients[]` **exactly** - and `localClient[]` too, if the
  HC runs on the same physical machine as the server.
- If you are launching headless clients through a managed hosting panel's own "launch N headless
  clients" automation rather than a raw `-client -connect=<serverIP>` command line, treat that
  automation as a separate, unverified layer - some panels have known bugs specific to their
  auto-launch feature. Testing one HC launched manually via a raw command line against the same
  server isolates whether the panel's automation is the actual cause.

## How it works

1. **Detection.** Every machine calls `Waldo_fnc_HeadlessDetectLocal` from `init.sqf`, gated behind
   WMP's ordered feature-runtime snapshot handshake (the same one AI rebalance and improved
   helicopter landing use). A headless client is identified with the standard, version-stable test
   `!isDedicated && !hasInterface`. The server and every real player are no-ops here. If
   `Waldo_Headless_Enable` is false, detection still runs (harmless) but the registration request
   below is never sent.
2. **Registration.** A detected headless client asks the server to register it and retries that
   authenticated request for at most 30 seconds. This handles the dedicated-server startup window
   where the HC process is connected but its `HeadlessClient_F` entity is not yet visible. The server
   registry is repeat-safe, so a retry refreshes the existing row rather than duplicating it.
   (`Waldo_fnc_HeadlessRegisterClient`), which verifies the remote owner controls an engine
   `HeadlessClient_F` virtual entity. Do not use `allPlayers` as a rejection test here: Arma includes
   headless clients in `allPlayers`. A verified HC is then added to
   `Waldo_Headless_Clients`. If ACE Headless is loaded, ACE is the sole automatic distributor and
   WMP listens for verified post-transfer events; this avoids two schedulers racing over the same
   group. Without ACE Headless, registration immediately starts WMP's own rebalance pass.
3. **Rebalancing.** When WMP owns automatic distribution, `Waldo_fnc_HeadlessRebalance` walks every group in the mission, works out which
   *eligible* ones should move to whichever connected headless client currently has the fewest
   assigned/queued groups, and queues them in `Waldo_Headless_MigrationQueue`.
4. **Paced migration.** `Waldo_fnc_HeadlessMigrationWorker` drains that queue one group at a time,
   `Waldo_Headless_MigrationPaceSeconds` (default 3s) apart, calling
   `Waldo_fnc_HeadlessMigrateGroup` - the single funnel every actual `setGroupOwner` call in this
   rework goes through, so `Waldo_Headless_ManagedGroups` never drifts from reality. Migrating many
   groups back-to-back in the same frame is a known source of a server hitch on a busy mission; this
   is the same reason established headless-client community tooling paces its own transfers instead
   of moving everything the instant it becomes eligible.
   The destination then confirms the group is local before WMP reapplies the selected AI profile.
   Successful handoffs log `[WMP HEADLESS] Adoption complete` with owner, unit counts and profile;
   a timeout is reported by the `headless-ai-adoption` diagnostic instead of being silently ignored.
   If ACE Headless performs the migration instead, WMP listens to ACE's documented
   `ace_headless_groupTransferPost` event on the destination HC, applies the same profile, and sends
   an authenticated result to the server. The server RPT then records `[WMP AI] Verified HC adoption`.
5. **Disconnect recovery.** `initServer.sqf` installs a `HandleDisconnect` mission event handler
   (`Waldo_fnc_HeadlessReassignOnDisconnect`). When a headless client disconnects, its groups return
   to the server immediately (not through the paced queue - losing AI ownership briefly is worse than
   a small hitch here), and a rebalance pass immediately offers them to any other connected headless
   client. This is event-driven - there is no polling loop watching for disconnects.

## Live Zeus triage and ownership overlay

When `Waldo_Headless_Enable` is `true`, WMP adds a dedicated **WMP Headless Client** category in
Zeus. It is absent when HC support is disabled. **Toggle Debug Overlay** enables both the extended
RPT/system-chat trail and a curator-only 3D ownership overlay:

- orange `SERVER` labels identify AI groups still owned by the server;
- blue labels name the connected HC which owns the group;
- yellow `OWNER n` labels identify an unexpected non-HC network owner;
- red `MISMATCH` labels show that WMP's managed registry disagrees with Arma's live `groupOwner`;
- every label also includes the group callsign and current AI count, so colour is not required.

The overlay reads current ownership continuously and follows migrations without re-running a
module. It is shown only to assigned curators and is replayed for a JIP curator while debug remains
enabled. **Force Rebalance Now** reports how many groups were newly queued and how many HCs are
connected. **Manual Group Handoff** lists nearby AI-only groups and named destinations. The normal
**Diagnostics - Run Full Pack Audit** module continues to report client count, distribution owner,
managed/excluded groups, adoption acknowledgements, failed transfers, ownership mismatches and the
migration queue in the RPT.

## Eligibility

### WMP feature assets always remain on the server

Headless clients receive ordinary eligible mission AI only. WMP state-machine assets that require
continuous server-local control are never offloaded: Paradrop aircraft and jump groups, Airborne
Gunships, Dynamic AA, Transport Services and WMP AI convoys stay on server owner `2`. Their
registries, waypoint controllers, cleanup and live transitions are server-authoritative, so
splitting crew ownership would create races and broken behaviour.

All other AI-crewed helicopters also remain server-owned while improved helicopter landing is
installed. Live dedicated testing showed a separate engine/locality failure: ACE Headless transferred
fresh airborne helicopter groups successfully, but the aircraft lost stable flight and struck the
terrain within three to four seconds, before WMP's landing controller had activated. WMP therefore
sets ACE's public `acex_headless_blacklist` on every non-UAV helicopter as it is created and rejects
helicopter groups in its own automatic and manual migration paths. This does **not** disable WMP AI
skill profiles for helicopter crew; it only keeps their flight simulation and AI ownership on the
server. Infantry and ground vehicles remain eligible for HC offloading.

Dynamic AO is the deliberate exception. Its groups are temporarily pinned while the server creates
their units, vehicles and waypoints. Once the AO registry is complete, those temporary exclusions
are removed and the finished groups may be distributed to HCs. The AO registry and cleanup remain
server-authoritative; locality-sensitive movement and the WMP AI profile run on the group owner.

Each feature marks its group/vehicle `Waldo_ServerOwnedFeature`. The scheduler filters that flag and
the final migration function checks it again immediately before `setGroupOwner`. This closes the
case where a group was queued just before feature registration. WMP also sets ACE Headless's vehicle
blacklist. Diagnostics report the exclusions as `headless-wmp-server-owned`.

A group is migrated only when **all** of the following hold. Anything excluded is recorded (with a
reason) in `Waldo_Headless_ExcludedGroups`, refreshed on every rebalance pass:

| Excluded when... | Reason logged |
|---|---|
| The group is empty | `empty` |
| Any member (including the leader) is a human player | `player-led` |
| WMP classifies the group or crewed vehicle as a server-owned feature | `wmp-server-owned` |
| Any member is crewing a helicopter | `helicopter-flight-locality` |
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
- **Adoption** - a per-unit engine `Local` event handler reapplies AI skill state whenever an
  ordinary eligible unit's locality changes. Improved helicopter landing also retains its local
  tracker guard, but automatic and manual HC distribution no longer migrate helicopters.

The one system found *not* to redispatch correctly, Dynamic AO's patrol-waypoint setup
(`Waldo_fnc_DynamicAOAddPatrolWaypoints`), was fixed to match the same redispatch pattern as part of
this rework.

## Real-time systems pin themselves server-side by default

Confirmed live: **ACE's own `ace_headless` module is a separate, uncoordinated mover** - if that
required-mod feature (not WMP's own system) is what's actually redistributing groups on a mission,
none of WMP's eligibility rules, settle-time or pacing above apply, since ACE decides independently.
Its own "Full Rebalance" behaviour moves every eligible group immediately with **no settle-time grace
period at all**, which can race a WMP system's own in-progress setup or simply move a group WMP
expects to keep continuously driving.

For that reason, `Waldo_fnc_GunshipRegister`, the shared paradrop flight-route builder
(`Waldo_fnc_ParadropBuildFlightRoute`, used by both `Waldo_fnc_ParadropQuickFlightSetup` and
`Waldo_fnc_ParadropCreateDropZone`), `Waldo_fnc_DynamicAACreate`, and `Waldo_fnc_SimpleAiConvoy` pin
their own managed vehicle(s) server-side by default via `Waldo_fnc_HeadlessPinCrew`. That call sets
**both** `Waldo_Headless_ExcludeGroup` (protects against WMP's own native rebalance) **and** ACE's own
`acex_headless_blacklist` on the vehicle (protects against `ace_headless`, which excludes any group
with units in a blacklisted vehicle) - the pin holds regardless of which headless system a mission
actually uses.

**Paradrop and Gunship carry a second, independent reason to pin, beyond just desyncing a watcher
script.** Both apply mission-maker-configured setup once - flight altitude/speed/direction and the
scripted standby/green/red waypoint route for Paradrop, turret profiles/orbit/service policy for
Gunship - to a specific aircraft/group, and never reapply it. A bare `setGroupOwner` does not replay
that setup, so migrating either mid-operation would silently drop the mission maker's own configured
flight behaviour, not merely go stale until the next tick. Any custom system with the same shape - a
one-shot configuration script bound to a specific managed vehicle/group that never re-applies itself -
should pin the same way.

**Dynamic AO and Transport Services are deliberately not pinned** - both are specifically designed
(and, for Dynamic AO, tested) to survive migration, and both name headless offloading as an intended
use case rather than a risk: Dynamic AO's patrol-waypoint redispatch (see above), and Transport
Services' own `Logistics\TransportServices\transportDispatchLocal.sqf`, written explicitly as
"current owner executes" - it re-targets itself to whichever machine currently owns the driver group,
so a mid-route migration is a supported case, not a failure mode. If a specific Dynamic AO deployment
needs to stay server-side anyway, call `[_object] call Waldo_fnc_HeadlessPinCrew;` on it yourself.

```sqf
// Pin any other custom AI vehicle/group server-side against both WMP's native rebalance and
// ACE's ace_headless module:
[_vehicle] call Waldo_fnc_HeadlessPinCrew;
```

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

## Extended debug output

Off by default (`Waldo_Headless_Debug` in `MissionConfig\headlessConfig.sqf`). The four core events
(registration, rebalance pass, migration, disconnect) already write a one-line `diag_log` entry to
RPT unconditionally - that baseline trail is one-shot-per-event and cheap enough to always keep.
`Waldo_Headless_Debug` adds the noisier, genuinely optional extra detail a mission maker only wants
while actively diagnosing HC behaviour: per-client load tables on every rebalance pass, an
exclusion-reason tally, migrated-group unit counts, and disconnect/reassign summaries. Routed through
`Waldo_fnc_HeadlessDebugLog`, which writes the shared `[WMP DIAG]` frame (`Waldo_fnc_DiagnosticLog`)
plus a hosted-server `systemChat` line (matching `Waldo_fnc_RunDiagnostics`'s own visibility
convention - a genuine dedicated server has no console to show it to and relies on RPT). Costs nothing
when off: a single `getVariable` check at each of the four call sites.

This is the direct successor to the legacy `WerthlesHeadless.sqf`'s own in-mission "Toggle WHK Debug"
action (`WHKDEBUGHC`) - the same "flip debug on the fly, get instant confirmation" intent, carried
into WMP's own `[WMP DIAG]`/notification-card conventions instead of that script's dedicated
`WHKDEBUGGER`/hint plumbing, and extended to be curator-triggerable from Zeus rather than a single
hard-coded admin's `addAction`:

```sqf
[] call Waldo_fnc_HeadlessDebugToggle;      // flip the current state
[true] call Waldo_fnc_HeadlessDebugToggle;  // force on
```

Or use the **Headless Client - Toggle Debug** ZEN module ("Waldos Mission Modules" > WMP Mission
Tools) - no dialog, it flips the state immediately and confirms the new state with a WMP notification
card to every assigned curator. No mission restart is required either way.

## Manual control from Zeus

Two further modules under **WMP Mission Tools** give a curator direct control over handoffs, on top
of the always-running automatic pass:

- **Headless Client - Force Rebalance Now** - runs one `Waldo_fnc_HeadlessRebalance` pass immediately.
  This still applies every normal eligibility rule (start delay, settle time, exclusions) - it only
  skips waiting for the next automatic trigger (registration or disconnect), useful right after
  enabling the feature mid-test or clearing a group's `Waldo_Headless_ExcludeGroup` flag.
- **Headless Client - Manual Handoff** - a dialog listing the 10 nearest eligible AI groups to where
  the module was placed (no human leader/member, nearest first) and a destination: auto-balance
  (whichever connected client currently has the fewest managed groups), return to server, or a named
  connected headless client. Applies immediately via `Waldo_fnc_HeadlessManualHandoff`, which still
  refuses a player-led group and still routes through `Waldo_fnc_HeadlessMigrateGroup` - the single
  funnel every migration in this rework uses, so the registry and diagnostics never drift regardless
  of whether a move was automatic or curator-directed.

```sqf
[] call Waldo_fnc_HeadlessForceRebalance;
[_group, "AUTO"] call Waldo_fnc_HeadlessManualHandoff;   // best-load connected client
[_group, "SERVER"] call Waldo_fnc_HeadlessManualHandoff; // force back to the server
[_group, "HC:4"] call Waldo_fnc_HeadlessManualHandoff;   // exact live HC owner shown by diagnostics
```

The ZEN destination list is rebuilt from the server's live HC registry and shows each HC owner plus
its current managed-group count. If that HC disconnects before confirmation, the request is rejected
instead of silently moving the group to the server.

**All three of these modules - Toggle Debug included - are registered only when
`Waldo_Headless_Enable` is true.** Every other WMP ZEN module registers unconditionally because it's
useful regardless of mission config; a Zeus menu offering to toggle headless debug output or hand
groups to a headless client would be pure clutter (and a misleading affordance) on the vast majority
of missions that never turn this system on. Registration happens in a short bounded wait for the same
`Waldo_SharedFeatureConfigReady` sentinel `initPlayerLocal.sqf` itself waits on, since `Waldo_Headless_Enable`
is SHARED-scope config loaded by `init.sqf` and there is no guaranteed ordering between `init.sqf` and
`initPlayerLocal.sqf`. `Waldo_ZenModuleCount` is 48 without these three, 51 with them -
`Waldo_fnc_RunDiagnosticsClient`'s `core-modules` check accepts either value as `LOADED`, since a
diagnostics run that lands inside that short registration window would otherwise report a false error
on a perfectly healthy headless-enabled mission.

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

## What you must test for each mission

WMP's implementation has been exercised on dedicated servers, but enabling a Headless Client still
changes where ordinary AI commands execute. Test the actual AI mods and vehicle types used by your
mission before relying on it for an event:

1. Start with one HC and the debug overlay enabled.
2. Confirm infantry and ground-vehicle groups change from `SERVER` to the expected HC owner.
3. Give migrated groups ordinary move, combat and vehicle waypoints.
4. Confirm WMP-owned real-time aircraft remain on the server.
5. Disconnect and reconnect the HC; confirm its groups return to the server and may rebalance.
6. Join as a player after the mission has started and run Mission Diagnostics.

Pay particular attention to crewed ground vehicles. Arma normally moves vehicle locality with the
crew group, but third-party AI scripts can still issue local commands on the old owner. If a vehicle
becomes unresponsive after migration, exclude that group or disable the conflicting distributor;
do not try to solve it by transferring WMP's aircraft state machines.

## See also

- [Mission Diagnostics](Mission-Diagnostics) - the general diagnostics report this feature feeds into.
- [Optional Third-Party Scripts (Player Markers)](Third-Party-Scripts-Headless-Client-And-Player-Markers) - the legacy, superseded WerthlesHeadless.sqf entry point.
- `releaseVerificationAndDeployment/fullArmaAudit/PROCESS.md` - the repeatable full-pack test process.

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)

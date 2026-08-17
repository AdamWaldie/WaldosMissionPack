# Headless client support

WMP ships a **native, server-authoritative** headless-client (HC) system. Use this for any new or
current mission — the older `WerthlesHeadless.sqf` third-party script described near the bottom of
this file is legacy, disabled by default, and kept only for reference; do not recommend it.

Player markers (a separate, unrelated third-party script) are also covered below.

## Native headless client support (`MissionConfig\headlessConfig.sqf`)

**Off by default.** Both `Waldo_fnc_HeadlessDetectLocal` (every machine) and
`Waldo_fnc_HeadlessRegisterClient` (server) are no-ops while disabled — connecting a headless
client to a mission that hasn't turned this on has no effect at all.

```sqf
// MissionConfig\headlessConfig.sqf
["Waldo_Headless_Enable", false],              // MISSION MAKER: master switch
["Waldo_Headless_StartDelaySeconds", 30],      // ADVANCED: grace period before any migration begins
["Waldo_Headless_MinGroupAgeSeconds", 10],     // ADVANCED: per-group settle time before eligibility
["Waldo_Headless_MigrationPaceSeconds", 3],    // ADVANCED: pause between each queued migration
["Waldo_Headless_Debug", false]                // TROUBLESHOOTING: verbose per-event RPT detail, toggle live from Zeus
```

Only enable it after running the manual HC test matrix (`wiki/Headless-Client-Support.md`) against
the mission's actual mod set — this system has not been verified against every third-party AI mod,
and a mission's own locality-sensitive scripts need to be tested with ownership migration in mind.

**Eden setup**: place one Playable "Headless Client" Virtual Entity (3DEN Systems/Logic category)
per headless-client slot wanted. WMP identifies a headless client purely by
`!isDedicated && !hasInterface` at runtime — unlike some third-party HC tooling, the slot's name or
variable name doesn't matter. `WMP_Compositions/[WMP]Headless_Client_Setup_Example` drops in five
pre-flagged slots (`HC_1`-`HC_5`) at once if that's faster than placing them by hand.

**A group is eligible for migration when**: it has no human player as leader/member, hasn't set
`Waldo_Headless_ExcludeGroup` to `true` on itself (the opt-out any WMP subsystem or mission script
can use — must be set server-side), isn't `sideLogic`, isn't crewing a registered Airborne Gunship
aircraft, has existed at least `Waldo_Headless_MinGroupAgeSeconds`, and is currently local to the
server. AI helicopter groups are always kept server-side (a safety rule, not a setting — dedicated
testing showed airborne helicopters diving into terrain after a group transfer).

**Real-time WMP systems pin their own managed vehicles automatically** (`Waldo_fnc_GunshipRegister`,
Paradrop's flight-route builder, `Waldo_fnc_DynamicAACreate`, `Waldo_fnc_SimpleAiConvoy`) via
`Waldo_fnc_HeadlessPinCrew`, so migrating them mid-operation can never silently drop a mission
maker's configured setup. Dynamic AO and Transport Services are deliberately *not* pinned — both are
specifically built to redispatch correctly after migration.

**ACE's own `ace_headless` module is a separate, uncoordinated mover** if a mission also has it
active — it ignores all of WMP's eligibility rules, settle-time and pacing, and moves every eligible
group immediately. The pinning above (which also sets `acex_headless_blacklist`) protects against it
too.

**Diagnostics**: `Waldo_fnc_HeadlessGetDiagnostics` (folded into WMP Diagnostics) reports connected
HC count, assigned-group count, excluded groups with reasons, failed transfers, and registry/reality
consistency.

**Actually connecting an HC process to the server is outside WMP's scope** (`server.cfg`
`headlessClients[]`, the `-client -connect=<serverIP> -password=<password>` launch parameters) — see
the separately-downloaded **Headless Client Kit** release artifact (`WMP_HC-<version>.zip`,
`HeadlessClientKit/` in the repo) for a `server.cfg` snippet, launch scripts, and a local
server+HC rehearsal script. This kit is never part of the main WMP pack build and has nothing to do
with the `.claude` skill folder — point a user there when they ask "how do I actually run a headless
client," as opposed to "how do I turn on HC support in my mission" (which is everything above).

## Player markers (third-party script, unrelated to headless clients)

Dynamic map markers for players (optionally AI): driver/pilot, vehicle name, passenger count,
click-to-expand passenger list. **Use only when ACE map markers aren't an option** for the group.
Loaded through the same hollow launcher as the legacy HC script below:

```sqf
// init.sqf - uncomment to enable:
[] execVM "MissionScripts\ThirdPartyScripts\ThirdPartyScriptInit.sqf";
```

`ThirdPartyScriptInit.sqf` itself has each script's call line separately commented out — open it and
uncomment only the player-markers line, not the legacy HC line below it.

```sqf
0 = ["players"] execVM "MissionScripts\ThirdPartyScripts\player_markers.sqf";
```

Options (combinable): `"players"`, `"ais"`, `"allsides"`, `"all"`, `"stop"`. Created locally on each
client; calling again replaces the previous run.

## Legacy: Werthles' Headless Kit (`WerthlesHeadless.sqf`) - do not recommend for new setup

Superseded by the native system above. Kept unmodified in the repository, disabled by default, for
reference only — do not suggest re-enabling it alongside the native system; the two are not designed
to run together. Only mention this section if a user is specifically asking about an existing
mission that already uses it and wants to understand or migrate off it.

```sqf
[true, 30, false, true, 30, 10, true, []] execVM "MissionScripts\ThirdPartyScripts\WerthlesHeadless.sqf";
```

Params: `[recurring, checkInterval, debugForEveryone, useAdvancedDistribution, startDelay,
ownerChangePause, printSetupReport, badNameSubstrings]`. Full documentation is in the header of
`WerthlesHeadless.sqf` itself.

## Gotchas

- Works alongside `ai-rebalance.md`'s AI skill tuning — offloading doesn't change how skill profiles
  apply, both are locality-aware.
- If asked to combine with `misc-mission-maker-tools.md`'s AI convoy system, no special interaction —
  both operate on AI groups independently (Transport Services' own dispatch logic already redispatches
  itself to whichever machine currently owns a convoy's driver group).

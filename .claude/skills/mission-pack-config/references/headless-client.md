# Headless client + player markers (third-party scripts)

Two optional, unrelated scripts kept separate from WMP's normal systems and
**disabled by default**, loaded through one entry point so `init.sqf` stays
clean. No `MissionConfig` file involved — this predates the migration and
is intentionally still a plain `execVM` toggle.

## Enabling

In `init.sqf`, uncomment the loader line:

```sqf
// Remove the // to enable headless client and/or player markers
[] execVM "MissionScripts\ThirdPartyScripts\ThirdPartyScriptInit.sqf";
```

`ThirdPartyScriptInit.sqf` is a "hollow" launcher — inside it, each script's
own call line is separately commented out. Open it and uncomment whichever
you actually want.

## Player markers

Dynamic map markers for players (optionally AI): driver/pilot, vehicle
name, passenger count, click-to-expand passenger list. **Use only when ACE
map markers aren't an option** for the group.

```sqf
0 = ["players"] execVM "MissionScripts\ThirdPartyScripts\player_markers.sqf";
```

Options (combinable): `"players"`, `"ais"`, `"allsides"`, `"all"`, `"stop"`.
Created locally on each client; calling again replaces the previous run.

## Headless client offload

Offloads AI groups onto one or more Headless Client instances, splitting
evenly. **Multiplayer only**, requires an HC slot placed in the mission and
a host that can connect headless clients.

```sqf
[true, 30, false, true, 30, 10, true, []] execVM "MissionScripts\ThirdPartyScripts\WerthlesHeadless.sqf";
```

Params (leaving them as shipped is recommended): `[recurring, checkInterval,
debugForEveryone, useAdvancedDistribution, startDelay, ownerChangePause,
printSetupReport, badNameSubstrings]`. Full documentation is in the header
of `WerthlesHeadless.sqf` itself.

## Gotchas

- Works alongside `ai-rebalance.md`'s AI skill tuning — offloading doesn't
  change how skill profiles apply, both are locality-aware.
- If asked to combine with `misc-mission-maker-tools.md`'s AI convoy system,
  no special interaction — both operate on AI groups independently.

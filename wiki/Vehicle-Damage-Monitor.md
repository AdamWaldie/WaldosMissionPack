# Vehicle Damage Monitor

> **Use this page when:** you need to inspect a vehicle's hit-point damage during a test.

This local debug script watches the vehicle under your cursor and displays its hit-point damage in an Arma hint. It does not repair the vehicle, publish diagnostics to other players or install a player-facing WMP service.

## Quick setup in a test session

Aim at a vehicle and run this in the debug console with **Local Execute**:

```sqf
[] execVM "MissionScripts\MissionMakerResourceScripts\vehicleDamageMonitor.sqf";
```

The script samples damage about every 0.2 seconds while that vehicle remains alive. It calls `hintSilent`, so it can replace another local hint. Keep it out of a normal player mission.

## Script call and result

| Input | Type | Default | Effect |
| --- | --- | --- | --- |
| Arguments | None | None | The script reads the local `cursorObject` Object when it starts. |
| Execution | `execVM` call | Manual | Returns an Arma Script handle immediately. |
| Watcher | Script handle in `real_vicwatch` | None before execution | Runs locally until its vehicle dies or the watcher is stopped. |

The file tries to terminate `real_vicwatch` before starting a new watcher. That variable may be undefined on the first run and cause a script error. The tool is useful for manual diagnosis but is not a dependable mission feature. It has no JIP state.

## If the display does not start

Check that your cursor was on a vehicle when you ran the script. Read your local `.rpt` for the possible first-run `real_vicwatch` error. Do not treat a lack of display as evidence that the vehicle has no damage.

## See also

- [Mission Diagnostics](Mission-Diagnostics)
- [Mission-Maker Resource Scripts](Mission-Maker-Resource-Scripts)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)

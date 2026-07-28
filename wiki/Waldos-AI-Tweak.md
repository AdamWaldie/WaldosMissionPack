# Waldo's AI Tuning

> **Use this page when:** you need to choose and configure WMP's day or night AI behavior adjustments.

_Associated Files: `MissionScripts/AiScripting/AISkillAdjustmentSystem.sqf`; `aiRebalanceInit.sqf`; `aiApplyProfile.sqf`; `aiRebalanceStop.sqf`_

## Overview

The AI rebalance applies named, bounded skill profiles to editor, scripted and Zeus-spawned AI. It runs where each AI unit is local, so dedicated servers and headless clients remain consistent. Players are never modified.

The compatibility configuration in `init.sqf` keeps the historical behavior:

```sqf
Waldo_AIRebalance_Enable = true;
Waldo_AIRebalance_Profile = "LEGACY";
["DAY", Waldo_AIRebalance_Profile] call Waldo_fnc_AITweak;
```

## Built-in profiles

| Profile | Intended use |
|---|---|
| `LEGACY` | Existing mission compatibility; very capable and highly accurate |
| `PUBLIC` | Lower lethality and slower target acquisition for open public sessions |
| `STANDARD` | Balanced cooperative default for new missions |
| `VETERAN` | Faster and more accurate opposition without maximum skills |

Change only the profile name to select a baseline. The wrapper `Waldo_fnc_AITweak` remains supported, while new code can call `Waldo_fnc_AIRebalanceInit` directly.

Zeus can use **AI Rebalance - Control** to switch the mode or built-in profile and immediately reapply it across server, clients and headless clients. Custom scripted profiles remain available through the API.

## Day and night modes

`DAY` uses the selected base profile. `NIGHT` also responds to current illumination: AI with night vision retain useful spotting, while AI without it receive a stronger spotting reduction. Thresholds remain mission-configurable through `Waldo_AI_DarknessThreshold`, `Waldo_AI_NightSpotWithNVG` and `Waldo_AI_NightSpotWithoutNVG`.

When LAMBS Danger is loaded, AI will trigger a broader range of tactical behaviours (flanking, suppression, bounding overwatch). WMP's elevated `general` and `commanding` values are tuned specifically to complement LAMBS — the combination produces more tactically varied AI without making them unfairly lethal.

## Mission overrides

Add or replace named profiles before initialisation:

```sqf
private _profiles = missionNamespace getVariable ["Waldo_AI_Profiles", createHashMap];
_profiles set ["CUSTOM", createHashMapFromArray [
    ["aimingSpeed", 0.40], ["aimingAccuracy", 0.35], ["aimingShake", 0.50],
    ["spotTime", 0.60], ["spotDistance", 0.70], ["commanding", 0.75],
    ["general", 0.65], ["courage", 0.75], ["reloadSpeed", 0.70]
]];
missionNamespace setVariable ["Waldo_AI_Profiles", _profiles];
["DAY", "CUSTOM"] call Waldo_fnc_AIRebalanceInit;
```

`Waldo_AI_FactionOverrides` maps faction classnames to partial skill maps. `Waldo_AI_RoleOverrides` does the same for upper-case `textSingular` role names. Each override layers on top of the selected profile and all values are clamped to `0`–`1`.

`Waldo_AI_ApplyMode` accepts `BOTH`, `EXISTING` or `NEW`. `Waldo_AI_IncludedSides`, `Waldo_AI_IncludedFactions`, `Waldo_AI_ExcludedFactions` and `Waldo_AI_ExcludedClasses` provide coarse filters; set `Waldo_AI_Exclude = true` on an individual unit for a precise opt-out. `Waldo_AI_SkillVariance` adds bounded per-unit variation after all overrides.

The feature records the original named skills before its first application. With `Waldo_AI_RestoreOnStop` enabled, `Waldo_fnc_AIRebalanceStop` restores those values. A locality handler reapplies the selected profile when ownership moves between server and headless clients.

## See also

- [Optional Feature Systems](Optional-Feature-Systems)
- [Optional Feature Extensions](Optional-Feature-Extensions)
- [AI Convoy System](AI-Convoy-System)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)

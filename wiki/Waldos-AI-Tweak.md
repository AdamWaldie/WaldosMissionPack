# Waldo's AI Tuning

> **Use this page when:** you need to choose and configure WMP's day or night AI behavior adjustments.

_Associated Files: `MissionScripts/AiScripting/AISkillAdjustmentSystem.sqf`; `aiRebalanceInit.sqf`; `aiApplyProfile.sqf`; `aiRebalanceStop.sqf`_

## Overview

The AI rebalance applies named, bounded skill profiles to editor, scripted and Zeus-spawned AI. It runs where each AI unit is local, so dedicated servers and headless clients remain consistent. Players are never modified.

The compatibility configuration in `init.sqf` keeps the historical behavior:

```sqf
Waldo_AIRebalance_Enable = true;
Waldo_AIRebalance_Profile = "LINE";
["DAY", Waldo_AIRebalance_Profile] call Waldo_fnc_AITweak;
```

## Built-in profiles

| Internal key | ZEN name | Intended use |
|---|---|---|
| `LEGACY` | Existing Mission Balance | Compatibility with the established pre-profile behaviour |
| `MILITIA` | WMP Militia | Irregular opposition with slow acquisition and forgiving lethality |
| `LINE` | WMP Line | Trained regular opposition with restrained shooting precision |
| `VETERAN` | WMP Veteran | Fast, capable opposition without maximum or superhuman precision inputs |
| `ELITE` | WMP Elite | Highly capable opposition with strong sensing, decisions and weapon handling |

Change only the profile name to select a baseline. The wrapper `Waldo_fnc_AITweak` remains supported, while new code can call `Waldo_fnc_AIRebalanceInit` directly.

Zeus can use **AI Rebalance - Control** to switch the mode or built-in profile and immediately reapply it across server, clients and headless clients. Custom scripted profiles remain available through the API. Every tuned tier is prefixed with `WMP` in ZEN so it is not mistaken for the server's Arma difficulty preset. The older `PUBLIC` and `STANDARD` script keys remain supported aliases for `MILITIA` and `LINE` values.

## What the values control

WMP sets the nine supported Arma 3 sub-skills. `aimingAccuracy` controls leading, range/drop estimation, dispersion and recoil compensation; `aimingShake` controls steadiness; `aimingSpeed` controls rotation and stabilisation. `spotDistance` affects spotting ability and information accuracy, while `spotTime` affects reaction time. `commanding` controls group target sharing, `general` influences decision making, `courage` affects morale and `reloadSpeed` controls weapon switching/reloading. Arma 3 disables the old `endurance` sub-skill, so WMP does not expose it.

These are requested inputs, not guaranteed final values. The engine interpolates them through `CfgAISkill`, and the active server AI difficulty coefficients affect `skillFinal`. Test missions should inspect `skillFinal`, not assume that an input of `0.50` produces a final value of `0.50`. See Bohemia's official [AI Skill](https://community.bohemia.net/wiki/Arma_3:_AI_Skill), [setSkill](https://community.bohemia.net/wiki/setSkill), [skillFinal](https://community.bohemia.net/wiki/skillFinal) and [AI Config Reference](https://community.bohemia.net/wiki/Arma_3:_AI_Config_Reference) documentation.

## Day and low-light modes

`DAY` uses the selected base profile. `NIGHT` waits until illumination is below `Waldo_AI_DarknessThreshold`, then reduces the modern WMP profiles' combat, sensing, target-sharing and decision inputs. AI with an assigned NVG/HMD receive the gentler `Waldo_AI_NightNVGMultipliers`; unaided AI use `Waldo_AI_NightUnaidedMultipliers`. Equipping the unit is therefore the explicit way to offset low-light degradation. The compatibility profile retains its established absolute spotting controls through `Waldo_AI_NightSpotWithNVG` and `Waldo_AI_NightSpotWithoutNVG`.

AI behaviour mods can still change tactical decisions independently of these skill inputs. WMP does not assume or require one.

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
Waldo_AI_ProfileDisplayNames set ["CUSTOM", "WMP Recon Opposition"];
["DAY", "CUSTOM"] call Waldo_fnc_AIRebalanceInit;
```

Custom profile keys appear in the ZEN selector automatically. Add a friendly label to `Waldo_AI_ProfileDisplayNames`; otherwise ZEN shows the key itself. Define the same custom profile on every machine during mission setup because AI can become local to the server, a client or a headless client.

`Waldo_AI_FactionOverrides` maps faction classnames to partial skill maps. `Waldo_AI_RoleOverrides` does the same for upper-case `textSingular` role names. Each override layers on top of the selected profile and all values are clamped to `0`–`1`.

`Waldo_AIRebalance_Mode` selects the lighting variant: `DAY` or `NIGHT`. This is independent of
`Waldo_AI_ApplyMode`, which selects the AI population: `BOTH`, `EXISTING` or `NEW`.
`Waldo_AI_IncludedSides`, `Waldo_AI_IncludedFactions`, `Waldo_AI_ExcludedFactions` and
`Waldo_AI_ExcludedClasses` provide coarse filters; set `Waldo_AI_Exclude = true` on an individual
unit for a precise opt-out. `Waldo_AI_SkillVariance` adds bounded per-unit variation after all
overrides.

The feature records the original named skills before its first application. With `Waldo_AI_RestoreOnStop` enabled, `Waldo_fnc_AIRebalanceStop` restores those values. A server-side stop is authoritative for current machines and JIP players; AI remains stopped until `Waldo_fnc_AIRebalanceInit` or the ZEN control explicitly enables it again. A locality handler reapplies the selected profile when ownership moves between server and headless clients.

## See also

- [Optional Feature Systems](Optional-Feature-Systems)
- [Optional Feature Extensions](Optional-Feature-Extensions)
- [AI Convoy System](AI-Convoy-System)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)

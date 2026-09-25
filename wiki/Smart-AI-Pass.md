# Smart AI Pass

> **Use this page when:** you want non-player AI squads to behave more sensibly in combat without adding an AI mod.

_Associated Files: `MissionConfig/aiConfig.sqf`; `MissionScripts/AiScripting/SmartAIPass/` (`aiPassInit.sqf`, `aiPassStop.sqf`, `aiPassIsEligible.sqf`, `aiPassIsPaused.sqf`, `aiPassQueueJob.sqf`, `aiPassSchedulerTick.sqf`, `aiPassRegroupOnKill.sqf`, `aiPassRegroupStep.sqf`)_

The Smart AI Pass improves how AI groups behave. [Waldo's AI Tuning](Waldos-AI-Tweak) changes how
well they shoot and spot; this pass changes what they do. It covers every non-player AI group in the
mission, including Dynamic AO patrols and garrisons. It needs no mod beyond the pack's required CBA.
It is written from scratch for WMP. The design is informed by an audit of several community AI mods,
which kept their good ideas and fixed their locality, performance and network faults.

It is **off by default**. Each behaviour also has its own switch, so you only get what you turn on.

## Enable the pass

1. Open `MissionConfig\aiConfig.sqf`.
2. Change `Waldo_AIPass_Enable` from `false` to `true`.
3. Leave `Waldo_AIPass_Regroup_Enable` as `true`, or set it to `false` to turn that behaviour off.

That is all. The server starts the pass and hands it to any headless client that connects, including
one that joins late. Zeus can switch it on or off during play from **AI Control** (see below).

## Behaviours

| Behaviour | Switch | What the AI do |
|---|---|---|
| Survivor regroup | `Waldo_AIPass_Regroup_Enable` | When a squad is almost destroyed, its survivors walk to the nearest friendly squad and join it instead of wandering alone. Deliberately small teams such as sniper pairs and sentries are never merged. |

More behaviours are planned, each with its own switch: holding and garrison posture, building
clearing, artillery support, and full contact drills (bounding, flanking and assaults).

### How survivor regroup decides

- It only starts when someone dies. Nothing watches living soldiers, so a quiet mission costs nothing.
- The group must be down to `Waldo_AIPass_Regroup_MaxRemnantSize` living members (default 2) or fewer.
  All of them must be on foot, and the group must once have had at least
  `Waldo_AIPass_Regroup_MinimumPeakSize` members (default 3).
- The host is the nearest same-side infantry squad within `Waldo_AIPass_Regroup_SearchRadius`. It
  must be bigger than a remnant and stay within `Waldo_AIPass_Regroup_MaxGroupSize` after the merge.
- Survivors walk to the host leader and each joins once within `Waldo_AIPass_Regroup_JoinDistance`.
  If they stop making progress, or the time limit passes, they join where they stand and catch up
  in formation.
- Unconscious ACE casualties stay where they fell for a medic to reach.

## Which AI are affected

Every AI group on the sides in `Waldo_AIPass_IncludedSides` (default `WEST`, `EAST`, `GUER`) may be
included, except:

- any group containing a living player;
- AI used by other WMP features: Airborne Gunship, Transport Services (including a crew that has got
  out), Paradrop aircraft and jumpers, Dynamic AA, AI Convoy, dialogue speakers, and drones (for
  example Virtual Vehicle Depot UAVs);
- anything that fails the shared AI filters `Waldo_AI_IncludedFactions`,
  `Waldo_AI_ExcludedFactions` or `Waldo_AI_ExcludedClasses`;
- anything you opt out yourself.

To keep one group or unit out of the pass only, put this in its init field:

```sqf
this setVariable ["Waldo_AIPass_Exclude", true, true];            // unit
(group this) setVariable ["Waldo_AIPass_Exclude", true, true];    // whole group
```

`Waldo_AI_Exclude` still works too, and excludes the unit from every WMP AI change, including skill
profiles.

While ENDEX or SafeStart is active the pass holds all behaviour and resumes afterwards.

## Settings

| Setting | Default | Meaning |
|---|---|---|
| `Waldo_AIPass_Enable` | `false` | Master switch. `false` means no pass code runs anywhere. |
| `Waldo_AIPass_IncludedSides` | `["WEST", "EAST", "GUER"]` | Sides the pass may command. Civilians are left out by default. |
| `Waldo_AIPass_TickBudgetMs` | `1` | Milliseconds of work allowed per scheduler tick (4 ticks a second). |
| `Waldo_AIPass_LowFpsThreshold` | `25` | Below this machine FPS, behaviour steps run half as often. |
| `Waldo_AIPass_Regroup_Enable` | `true` | Survivor regroup on or off. |
| `Waldo_AIPass_Regroup_MaxRemnantSize` | `2` | Living members at or below this make a remnant. |
| `Waldo_AIPass_Regroup_MinimumPeakSize` | `3` | Groups that never reached this size are never merged. |
| `Waldo_AIPass_Regroup_SearchRadius` | `400` | Metres searched for a host squad. |
| `Waldo_AIPass_Regroup_MaxGroupSize` | `12` | Host size limit after the merge. |
| `Waldo_AIPass_Regroup_JoinDistance` | `30` | Metres from the host leader at which a survivor joins. |
| `Waldo_AIPass_Regroup_StuckSeconds` | `20` | Seconds without progress before survivors join where they stand. |
| `Waldo_AIPass_Regroup_TimeoutSeconds` | `120` | Limit for finding a host and for walking to it. |
| `Waldo_AIPass_Regroup_SettleSeconds` | `5` | Delay after a kill so deaths at the same moment are counted together. |

Script calls, if you need them:

```sqf
[] call Waldo_fnc_AIPassInit;   // on the server: start everywhere
[] call Waldo_fnc_AIPassStop;   // on the server: stop everywhere and hand groups back to their own orders
[group _unit] call Waldo_fnc_AIPassIsEligible;   // true if the pass may command this group
```

## Zeus control

**WMP AI & Combat > AI Control** (formerly *AI Rebalance - Control*) now has two more checkboxes:
**Smart AI Pass** and **Survivor regroup**. The change reaches every machine, including headless
clients that join later.

## Performance and network

- Runs only on the server and headless clients. Player machines never run pass code.
- One scheduler per machine, with a strict per-tick time budget. At least one job runs each tick,
  and jobs that do not fit wait their turn in rotation.
- Kill-driven. There are no fired-near handlers and no polling of living units.
- Adds no broadcasts of its own. Orders go only to units on their owning machine, and a merge never
  moves a group to another machine.

## Limitations

- Behaviour mods such as LAMBS can override movement orders while their own danger logic is
  active. Survivor regroup still completes, because stuck or late survivors join where they stand.
- If a remnant's group moves to another machine partway through, the move stops. The next kill in
  that group starts it again on the new owner.
- Peak strength is recorded where the group is owned. A group that took losses, then moved to a
  headless client, and then took more losses may not be recognised as a remnant.
- Paradrop jumpers keep their paradrop marker after landing, so they are excluded.

## Remove or diagnose

Mission diagnostics include two rows under area `ai`. `smart-ai-pass` shows whether the server
scheduler is running, how many jobs are queued and whether ENDEX or SafeStart has paused it.
`smart-ai-pass-regroup` shows completed regroups and units joined on the server. RPT lines are tagged
`[WMP AI PASS]`. Set `Waldo_AIPass_Enable` to `false`, or untick **Smart AI Pass** in Zeus, to remove
it completely.

## See also

- [Waldo's AI Tuning](Waldos-AI-Tweak)
- [Dynamic AO Generation](Dynamic-AO-Generation)
- [Headless Client Support](Headless-Client-Support)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)

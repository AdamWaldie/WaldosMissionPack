# Smart AI Pass

Optional behaviour improvements for non-player AI groups. Off by default. All settings are in
`MissionConfig\aiConfig.sqf` (`shared` scope). Edit that file; do not add a call to `init.sqf`.
`init.sqf` already starts the pass on the server when the switch is on, and the server replays the
start to headless clients.

```sqf
["Waldo_AIPass_Enable", true],                         // master switch (default false)
["Waldo_AIPass_IncludedSides", ["WEST", "EAST", "GUER"]], // sides the pass may command
["Waldo_AIPass_Regroup_Enable", true],                 // survivor regroup behaviour
```

- **Every behaviour has its own `Waldo_AIPass_<Behaviour>_Enable` switch.** Survivor regroup is the
  only behaviour shipped so far. Do not invent switches for planned behaviours (garrison, building
  clearing, artillery, contact drills); they do not exist yet.
- **Scope:** every non-player AI group on the included sides. It also honours the shared AI filters
  `Waldo_AI_IncludedFactions`, `Waldo_AI_ExcludedFactions` and `Waldo_AI_ExcludedClasses`.
- **Automatically excluded:** groups with a living player; Gunship, Transport Services (including
  dismounted crews), Paradrop aircraft and jumpers, Dynamic AA, AI Convoy, dialogue speakers,
  drones. Dynamic AO groups are included on purpose.
- **Manual opt-out:** `this setVariable ["Waldo_AIPass_Exclude", true, true];` on a unit, or on
  `group this`. `Waldo_AI_Exclude` also works and excludes the unit from every WMP AI change.
- **Survivor regroup tuning (ADVANCED):** `Waldo_AIPass_Regroup_MaxRemnantSize` (2),
  `_MinimumPeakSize` (3; smaller teams such as snipers are never merged), `_SearchRadius` (400 m),
  `_MaxGroupSize` (12), `_JoinDistance` (30 m), `_StuckSeconds` (20), `_TimeoutSeconds` (120),
  `_SettleSeconds` (5).
- **Performance tuning (ADVANCED):** `Waldo_AIPass_TickBudgetMs` (1 ms per 0.25 s tick) and
  `Waldo_AIPass_LowFpsThreshold` (25). Leave these alone unless profiling.
- **Pauses** while ENDEX or SafeStart is active.
- **Runtime:** Zeus **WMP AI & Combat > AI Control** has *Smart AI Pass* and *Survivor regroup*
  checkboxes. Script: `[] call Waldo_fnc_AIPassInit;` / `[] call Waldo_fnc_AIPassStop;` on the server.
- **Diagnostics:** rows `ai/smart-ai-pass` and `ai/smart-ai-pass-regroup`. RPT lines are tagged
  `[WMP AI PASS]`.

Wiki: `Smart-AI-Pass`.

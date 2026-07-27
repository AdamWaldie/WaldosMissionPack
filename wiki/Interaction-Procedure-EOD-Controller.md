# EOD Controller

The `wirecut` procedure represents a rugged field controller used to isolate and sever one live lead. It is suitable for bombs, demolition charges, vehicle sabotage, and booby-trapped equipment.

| Operating card | Active controller |
|---|---|
| ![EOD operating card](images/interaction-procedures/interaction-wirecut-briefing.png) | ![EOD controller](images/interaction-procedures/interaction-wirecut-active.png) |

## Operator procedure

Read the isolation order, then compare the bay, connector, insulation pattern, routed bus, and continuity requirement against the labelled looms. Select a candidate and run the continuity probe. The cutter unlocks only after a live reading has been acquired. Cutting the correct loom succeeds; cutting the wrong one, timing out, or confirming abort fails.

Colour is supplementary: every loom also has a connector, pattern, bay, bus, and acquired continuity label.

## Difficulty and configuration

Difficulty increases the number of independent readings that must agree, from one at easy to four at expert. It also changes loom count and time; it does not add arbitrary confirmation inputs.

```sqf
// [wireCount, timeLimit, title, verificationLevel]
[this, "wirecut", createHashMapFromArray [
    ["difficulty", "hard"],
    ["actionTitle", "Defuse Training Charge"],
    ["preset", "vehicleCharge"]
]] call Waldo_fnc_MiniGameInteractionSetup;
```

Valid configuration: `[wireCount(3-6,5), timeLimit(20), title("EOD CONTROLLER"), verificationLevel(1-4,derived)]`. Existing three-value configurations remain valid. For a live explosive, use the bomb-defusal setup/callback so a failed or aborted result triggers the mission's configured consequence.

[Shared state, callbacks, ACE conditions and reset](Waldos-Mini-Games-Interaction-Challenges#authoritative-lifecycle-and-mission-state)

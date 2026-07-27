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

Valid configuration: `[wireCount(3-6,5), timeLimit(20), title("EOD CONTROLLER"), verificationLevel(1-4,derived)]`. Existing three-value configurations remain valid.

## Live explosive setup

`Waldo_fnc_BombDefuseSetup` is a consequence wrapper around the shared field-equipment system, not a reduced second implementation. It defaults to `wirecut`, but `challengeId` may select any built-in procedure when another operation better represents how the device is secured. Every choice uses the shared operating card, UI, difficulty profiles, presentation presets, ACE and vanilla actions, authoritative state, callbacks, and accessibility settings. The wrapper only adds the live explosive consequence.

```sqf
[this, createHashMapFromArray [
    ["difficulty", "hard"],
    ["actionTitle", "Defuse Vehicle Charge"],
    ["equipmentTitle", "EOD CONTROL UNIT"],
    ["preset", "vehicleCharge"],
    ["detonateOnFailure", true],
    ["oneShot", true]
]] call Waldo_fnc_BombDefuseSetup;
```

Legacy array options such as `[["wireCount", 6], ["timeLimit", 15]]` remain supported. Explicit `wireCount`, `timeLimit`, `verificationLevel`, or `config` values override the curated difficulty mechanics.

For example, a generator-fed charge can require breaker routing instead of wire isolation:

```sqf
[this, createHashMapFromArray [
    ["challengeId", "circuit"],
    ["difficulty", "hard"],
    ["actionTitle", "Bypass Detonation Bus"],
    ["successVariable", "chargeDisarmed"],
    ["preset", "generatorBreaker"]
]] call Waldo_fnc_BombDefuseSetup;
```

`successVariable` is the preferred shared option. The older `defusedVariable` name remains a fallback for existing missions.

[Shared state, callbacks, ACE conditions and reset](Waldos-Mini-Games-Interaction-Challenges#authoritative-lifecycle-and-mission-state)

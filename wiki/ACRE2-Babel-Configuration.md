# ACRE2 Babel Configuration

> **Use this page when:** different sides or individual characters need one or more understood languages.

Babel is configured in the `babel` map inside `MissionConfig\acreConfig.sqf`. Language `[ID, display name]` pairs are registered once in the same declared order on every ACRE machine, including JIP clients. Do not add or reorder language definitions during play.

```sqf
["babel", createHashMapFromArray [
    ["enabled", true],
    ["languages", [["common", "Common"], ["en", "English"], ["ru", "Russian"], ["fr", "French"], ["ar", "Arabic"]]],
    ["sideDefaults", [["WEST", ["common", "en"], "en"], ["EAST", ["common", "ru"], "ru"]]],
    ["unitOverrides", [
        [["UID", "7656119..."], ["en", "ru"], "en"],
        [["VARIABLENAME", "interpreter_1"], ["en", "ru"], "ru"]
    ]],
    ["changeOnSideChange", false],
    ["followPlayerUnit", true]
]]
```

The shipped configuration demonstrates one shared language plus a unique language for each side, but keeps Babel disabled. Set `enabled` to `true` only when the mission wants language simulation. An override can grant a partial language set; interpreters do not have to understand every language. The initial speaking language must be in the understood list.

## Unit override selectors

Each override is `[[selector type, selector value], understood language IDs, initial speaking ID]`.
Rows are evaluated from top to bottom and the first match wins.

| Selector | Selector value | Use |
|---|---|---|
| `UID` | Player's Steam UID as text | Give one account the override regardless of its selected slot. |
| `VARIABLENAME` | Eden unit **Variable Name** as text | Give a particular playable character/slot the override. |
| `VARIABLE` | Same as `VARIABLENAME` | Retained shorthand; prefer the clearer full name in new missions. |

For example, `[["VARIABLENAME", "interpreter_1"], ["common", "en", "ru"], "ru"]`
matches the playable unit whose Eden Variable Name is `interpreter_1`. That unit understands Common,
English and Russian and initially speaks Russian. Matching uses Arma's `vehicleVarName` on the local
player object. A respawn framework that replaces the unit must preserve/reapply that Variable Name
for a slot-based override to continue matching; use `UID` when identity must follow the account.

When `followPlayerUnit` is true, Babel knowledge and the radio plan are reapplied after a local player-object replacement. When false, no unit-change handler is installed. By default a side change preserves learned languages; set `changeOnSideChange` to `true` only when side membership should redefine knowledge.

When Babel and the main ACRE configuration are enabled, the planned Babel diary record is created
during briefing setup without waiting for ACRE runtime initialization. Players can therefore read
their configured languages before pressing Continue. Runtime application later verifies those same
values through ACRE and replaces the record rather than adding a duplicate. The active wrapper is
`Waldo_fnc_BabelActivation`; the previous argument-based implementation remains available only as
`Waldo_fnc_BabelActivation_Legacy`.

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)

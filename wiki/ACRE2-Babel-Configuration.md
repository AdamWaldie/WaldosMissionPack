# ACRE2 Babel Configuration

> **Use this page when:** different sides or individual characters need one or more understood languages.

Babel is configured in the `babel` map inside `MissionConfig\acreConfig.sqf`. Language `[ID, display name]` pairs are registered once in the same declared order on every ACRE machine, including JIP clients. Do not add or reorder language definitions during play.

## Configure languages

Edit the `babel` block in `MissionConfig\acreConfig.sqf`. The shipped example contains five
language definitions and one default row for each side, but Babel starts disabled. Change
`enabled` to `true`, then adjust the rows your mission needs. WMP runs the setup for players,
including late joiners. No unit Init call is required.

| Setting or row | Type | Shipped default | What to supply |
| --- | --- | --- | --- |
| `enabled` | Boolean | `false` | Turn Babel on for this mission. |
| `languages` | Array of `[ID String, display name String]` rows | Five example languages | Define every language ID used below. Keep this list and its order fixed during play. |
| `sideDefaults` | Array of `[side ID String, understood IDs Array of Strings, speaking ID String]` rows | WEST, EAST, GUER and CIV examples | Give each side its starting knowledge and speaking language. |
| `unitOverrides` | Array of override rows | `[]` | Each row is `[[selector type String, selector value String], understood IDs Array of Strings, speaking ID String]`. First matching row wins. |
| `changeOnSideChange` | Boolean | `false` | `true` replaces a player's Babel assignment after a side change. |
| `followPlayerUnit` | Boolean | `true` | Reapply the assignment after a respawn framework replaces the local player object. |

The speaking ID must appear in that row's understood IDs. `Waldo_fnc_BabelActivation` is
WMP's automatic player-local wrapper. The mission maker does not pass these rows to it
or use its return value.

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
values through ACRE and replaces the record rather than adding a duplicate. The supported wrapper is
`Waldo_fnc_BabelActivation`; the obsolete argument-based implementation has been removed.

## If a language override does not apply

Check that Babel is enabled, the language ID exists in the `languages` list, and the initial speaking language appears in the unit's understood list. `VARIABLENAME` matches the Eden unit Variable Name, which a respawn replacement must preserve. Use `UID` when the override should follow the account instead of a slot.

## See also

- [Automated CEOI](ACRE2-Automated-CEOI-Document)
- [Long-Range Radio Presetting](ACRE-2-Long-Range-Radio-Presetting)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)

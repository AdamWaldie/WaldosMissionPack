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
        [["VARIABLE", "interpreter_1"], ["en", "ru"], "ru"]
    ]],
    ["changeOnSideChange", false],
    ["followPlayerUnit", true]
]]
```

The shipped configuration demonstrates one shared language plus a unique language for each side, but keeps Babel disabled. Set `enabled` to `true` only when the mission wants language simulation. An override can grant a partial language set; interpreters do not have to understand every language. The initial speaking language must be in the understood list.

When `followPlayerUnit` is true, Babel knowledge and the radio plan are reapplied after a local player-object replacement. When false, no unit-change handler is installed. By default a side change preserves learned languages; set `changeOnSideChange` to `true` only when side membership should redefine knowledge.

The Babel diary record is replaced rather than duplicated. The active wrapper is `Waldo_fnc_BabelActivation`; the previous argument-based implementation remains available only as `Waldo_fnc_BabelActivation_Legacy`.

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)

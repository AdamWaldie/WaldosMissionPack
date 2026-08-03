# ACRE2 Babel Configuration

> **Use this page when:** different sides or individual characters need one or more understood languages.

Babel is configured in the `babel` map inside `MissionConfig\acreConfig.sqf`. Language `[ID, display name]` pairs are registered once in the same declared order on every ACRE machine, including JIP clients. Do not add or reorder language definitions during play.

```sqf
["babel", createHashMapFromArray [
    ["enabled", true],
    ["languages", [["en", "English"], ["ru", "Russian"]]],
    ["sideDefaults", [["WEST", ["en"], "en"], ["EAST", ["ru"], "ru"]]],
    ["unitOverrides", [
        [["UID", "7656119..."], ["en", "ru"], "en"],
        [["VARIABLE", "interpreter_1"], ["en", "ru"], "ru"]
    ]],
    ["changeOnSideChange", false],
    ["followPlayerUnit", true]
]]
```

An override can grant a partial language set; interpreters no longer have to understand every language. The initial speaking language must be in the understood list. Validation rejects unknown language IDs, duplicate IDs, malformed overrides and a speaking language that is not understood.

When `followPlayerUnit` is true, Babel knowledge and the radio plan are reapplied after a local player-object replacement. When false, no unit-change handler is installed. By default a side change preserves learned languages; set `changeOnSideChange` to `true` only when side membership should redefine knowledge.

The Babel diary record is replaced rather than duplicated. The active wrapper is `Waldo_fnc_BabelActivation`; the previous argument-based implementation remains available only as `Waldo_fnc_BabelActivation_Legacy`.

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)

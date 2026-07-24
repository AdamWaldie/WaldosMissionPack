/*
 * Returns the canonical positional configuration for a built-in equipment
 * procedure and curated difficulty level.
 *
 * Arguments:
 * _challengeId - String - built-in procedure id
 * _difficulty  - String - easy/standard/hard/expert
 *
 * Return Value:
 * Array - independent configuration copy, or [] for an unknown procedure
 */
params [
    ["_challengeId", "", [""]],
    ["_difficulty", "standard", [""]]
];
_challengeId = toLower _challengeId;
_difficulty = toLower _difficulty;
private _difficultyIndex = ["easy", "standard", "hard", "expert"] find _difficulty;
if (_difficultyIndex < 0) then {_difficultyIndex = 1;};

private _profiles = switch (_challengeId) do {
    case "wirecut": {[
        [4, 35, "EOD CONTROLLER", 1], [5, 30, "EOD CONTROLLER", 2],
        [6, 30, "EOD CONTROLLER", 3], [6, 25, "EOD CONTROLLER", 4]
    ]};
    case "minesweeper": {[
        [4, 3, 0, "TRIGGER ANALYSER"], [5, 5, 0, "TRIGGER ANALYSER"],
        [7, 10, 90, "TRIGGER ANALYSER"], [8, 15, 75, "TRIGGER ANALYSER"]
    ]};
    case "keypad": {[
        [3, 9, 0, "ACCESS TERMINAL"], [4, 8, 0, "ACCESS TERMINAL"],
        [5, 8, 90, "ACCESS TERMINAL"], [6, 9, 75, "ACCESS TERMINAL"]
    ]};
    case "lockpick": {[
        [2, 3.2, 0.24, 0, "LOCK CYLINDER"], [3, 2.8, 0.16, 0, "LOCK CYLINDER"],
        [5, 2.3, 0.12, 60, "LOCK CYLINDER"], [6, 1.9, 0.09, 45, "LOCK CYLINDER"]
    ]};
    case "circuit": {[
        [3, 5, 0, "BREAKER CABINET"], [4, 3, 0, "BREAKER CABINET"],
        [5, 2, 60, "BREAKER CABINET"], [6, 1, 45, "BREAKER CABINET"]
    ]};
    case "repair": {[
        [3, 1, 5, 50, "MAINTENANCE HATCH"], [4, 2, 3, 40, "MAINTENANCE HATCH"],
        [5, 3, 2, 40, "MAINTENANCE HATCH"], [6, 4, 1, 35, "MAINTENANCE HATCH"]
    ]};
    case "radiotune": {[
        [2, 0.09, 0.75, 45, "COMMUNICATIONS UNIT"], [3, 0.05, 1, 40, "COMMUNICATIONS UNIT"],
        [4, 0.035, 1.5, 40, "COMMUNICATIONS UNIT"], [5, 0.025, 2, 35, "COMMUNICATIONS UNIT"]
    ]};
    case "pressure": {[
        [2, 1, 1.5, 60, "HYDRAULIC MANIFOLD"], [3, 1, 2, 50, "HYDRAULIC MANIFOLD"],
        [4, 2, 2.5, 50, "HYDRAULIC MANIFOLD"], [4, 3, 3, 40, "HYDRAULIC MANIFOLD"]
    ]};
    case "sequence": {[
        [3, 3, 1.05, 0, "CONTROL CONSOLE"], [4, 4, 0.85, 0, "CONTROL CONSOLE"],
        [5, 5, 0.85, 75, "CONTROL CONSOLE"], [6, 6, 0.85, 75, "CONTROL CONSOLE"]
    ]};
    case "commandinput": {[
        [3, 2, 4, 0, "TACTICAL UPLINK"], [4, 3, 3, 45, "TACTICAL UPLINK"],
        [5, 4, 2, 40, "TACTICAL UPLINK"], [6, 5, 1, 35, "TACTICAL UPLINK"]
    ]};
    default {[]};
};

if (_profiles isEqualTo []) exitWith {[]};
+(_profiles select _difficultyIndex)

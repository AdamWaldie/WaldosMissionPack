/*
 * Developer gallery for real in-engine field-equipment displays.
 * Arguments: [challengeId|"all", state, accessibilityOverrides]
 * States: BRIEFING, ACTIVE, HOVER, SELECTED, DISABLED, WARNING, SUCCESS, FAILURE, TIMEOUT.
 */
if (!hasInterface) exitWith {false};
params [["_challengeId", "all", [""]], ["_state", "BRIEFING", [""]], ["_accessibility", [], [[], createHashMap]]];
private _entries = [
    ["wirecut", [5, 0, "EOD CONTROLLER", 2], []],
    ["minesweeper", [5, 5, 0, "TRIGGER ANALYSER"], []],
    ["keypad", [4, 6, 0, "ACCESS TERMINAL"], []],
    ["lockpick", [3, 2.8, 0.16, 0, "LOCK CYLINDER"], []],
    ["circuit", [4, 3, 0, "BREAKER CABINET"], []],
    ["repair", [4, 2, 3, 0, "MAINTENANCE HATCH"], []],
    ["radiotune", [3, 0.05, 1, 0, "COMMUNICATIONS UNIT"], []],
    ["pressure", [3, 1, 2, 0, "HYDRAULIC MANIFOLD"], []],
    ["sequence", [4, 4, 0.85, 0, "CONTROL CONSOLE"], []],
    ["commandinput", [4, 3, 3, 0, "TACTICAL UPLINK"], []]
];
if (toLower _challengeId == "all") exitWith {[objNull, _entries] call Waldo_fnc_MiniGameEquipmentPicker};
private _entryIndex = -1;
{
    if ((_x select 0) == toLower _challengeId) exitWith {_entryIndex = _forEachIndex;};
} forEach _entries;
if (_entryIndex < 0) exitWith {systemChat format ["Unknown equipment id: %1", _challengeId]; false};
if (count _accessibility > 0) then {[_accessibility] call Waldo_fnc_MiniGameAccessibility;};
private _entry = _entries select _entryIndex;
private _opened = [
    _entry select 0,
    _entry select 1,
    {},
    {},
    player,
    ["EQUIPMENT_GALLERY", toUpper _state],
    _entry select 2
] call Waldo_fnc_MiniGameChallenge;
if (_opened) then {
    [_state] spawn {
        params ["_state"];
        waitUntil {uiSleep 0.01; !isNull (uiNamespace getVariable ["Waldo_MG_ActiveChallengeDisplay", displayNull])};
        private _display = uiNamespace getVariable ["Waldo_MG_ActiveChallengeDisplay", displayNull];
        [_display, _state] call Waldo_fnc_MiniGameEquipmentPreviewState;
        [_display, true] call Waldo_fnc_MiniGameEquipmentValidateDisplay;
    };
};
_opened

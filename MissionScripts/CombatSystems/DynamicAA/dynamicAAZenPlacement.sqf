/*
 * Author: WaldoTheWarfighter
 * Collects per-slot equipment choices and map positions, then submits one server-authoritative
 * Dynamic AA configuration. Profile mode only asks for positions. Exact mode asks for a class
 * for each requested slot, so one system may mix any configured radar, static, mobile and fighter
 * classes. The optional "use for remaining" choice avoids repeating identical selections.
 *
 * Arguments:
 * 0: centre <ARRAY> - detection centre chosen when the ZEN module was placed
 * 1: id <STRING> - generated runtime system id
 * 2: settings <HASHMAP> - validated common/profile settings from the staged ZEN dialogs
 * 3: catalogue <HASHMAP> - available class values and readable labels by asset category
 *
 * Return Value: Nothing.
 * Example: [_centre, _id, _settings, _catalogue] spawn Waldo_fnc_DynamicAAZenPlacement;
 * Current caller: Waldo_fnc_DynamicAAZen.
 */

params [
    ["_centre", [], [[]]],
    ["_id", "", [""]],
    ["_settings", createHashMap, [createHashMap]],
    ["_catalogue", createHashMap, [createHashMap]]
];
if !(hasInterface) exitWith {};
// Let the confirming ZEN dialog finish closing before opening another dialog or the map.
uiSleep 0;

private _notify = {
    params ["_message", ["_state", "INFO"]];
    ["DYNAMIC AA", _message, _state, "DYNAMIC_AA_PLACEMENT", 7] call Waldo_fnc_FeatureNotifyLocal;
};
private _cancel = {
    params ["_phase"];
    openMap false;
    [format ["Creation cancelled while selecting %1.", _phase], "WARNING"] call _notify;
    diag_log format ["[WMP DYNAMIC AA] ZEN placement '%1' cancelled during %2.", _id, _phase];
};
private _selectClass = {
    params ["_title", "_description", "_classes", "_labels", "_slot", "_total"];
    if (_classes isEqualTo []) exitWith {[false, "", false]};
    private _token = format ["Waldo_DynamicAA_ClassChoice_%1_%2", clientOwner, diag_frameNo];
    missionNamespace setVariable [_token, nil];
    [
        format ["Dynamic AA: %1 %2 of %3", _title, _slot, _total],
        [
            ["LIST", [_title, _description], [_classes, _labels, 0, 6]],
            ["CHECKBOX", ["Use for remaining", "Apply this class to every remaining slot in this category. You can still mix categories independently."], false]
        ],
        {
            params ["_values", "_arguments"];
            _arguments params ["_token"];
            _values params ["_class", "_useForRemaining"];
            missionNamespace setVariable [_token, [true, _class, _useForRemaining]];
        },
        {
            params ["_values", "_arguments"];
            _arguments params ["_token"];
            missionNamespace setVariable [_token, [false, "", false]];
        },
        [_token]
    ] call zen_dialog_fnc_create;
    waitUntil {uiSleep 0.05; !isNil {missionNamespace getVariable _token}};
    private _result = missionNamespace getVariable [_token, [false, "", false]];
    missionNamespace setVariable [_token, nil];
    _result
};
private _selectPosition = {
    params ["_message"];
    private _token = format ["Waldo_DynamicAA_MapChoice_%1_%2", clientOwner, diag_frameNo];
    missionNamespace setVariable [_token, []];
    [_message] call _notify;
    openMap true;
    onMapSingleClick format ["missionNamespace setVariable ['%1', _pos]; onMapSingleClick ''; true", _token];
    waitUntil {uiSleep 0.05; !visibleMap || {count (missionNamespace getVariable [_token, []]) > 0}};
    onMapSingleClick "";
    private _position = missionNamespace getVariable [_token, []];
    missionNamespace setVariable [_token, nil];
    _position
};

private _exactMode = (_settings getOrDefault ["assetSelectionMode", "PROFILE"]) == "EXACT";
private _categoryDefinitions = [
    ["radar", "Radar", "radarCount", "radarClasses", "radarLabels", true],
    ["static", "Static AA", "staticCount", "staticClasses", "staticLabels", true],
    ["mobile", "Mobile AA", "mobileCount", "mobileClasses", "mobileLabels", true],
    ["fighter", "Fighter", "fighterCount", "fighterClasses", "fighterLabels", false]
];
private _assignmentsByCategory = createHashMap;
private _positionsByCategory = createHashMap;
private _cancelled = false;

diag_log format ["[WMP DYNAMIC AA] ZEN placement '%1' started in %2 mode.", _id, _settings getOrDefault ["assetSelectionMode", "PROFILE"]];
{
    _x params ["_key", "_display", "_countKey", "_classesKey", "_labelsKey", "_needsPosition"];
    private _count = _settings getOrDefault [_countKey, 0];
    private _assignments = [];
    private _positions = [];
    private _repeatClass = "";
    for "_slot" from 1 to _count do {
        private _class = "";
        if (_exactMode) then {
            if (_repeatClass != "") then {
                _class = _repeatClass;
            } else {
                private _choice = [
                    _display,
                    format ["Choose the exact %1 class for this slot. Different slots may use different classes.", toLower _display],
                    _catalogue getOrDefault [_classesKey, []],
                    _catalogue getOrDefault [_labelsKey, []],
                    _slot,
                    _count
                ] call _selectClass;
                if !(_choice select 0) exitWith {_cancelled = true};
                _class = _choice select 1;
                if (_choice select 2) then {_repeatClass = _class};
            };
            if (_cancelled) exitWith {};
            _assignments pushBack _class;
        };
        if (_needsPosition) then {
            private _position = [format ["Click the map for %1 %2 of %3. Close the map to cancel.", _display, _slot, _count]] call _selectPosition;
            if (_position isEqualTo []) exitWith {_cancelled = true};
            _positions pushBack _position;
        };
    };
    _assignmentsByCategory set [_key, _assignments];
    _positionsByCategory set [_key, _positions];
    if (_cancelled) exitWith {[_display] call _cancel};
} forEach _categoryDefinitions;
if (_cancelled) exitWith {};

openMap false;
private _radarPositions = _positionsByCategory getOrDefault ["radar", []];
if (_radarPositions isEqualTo []) exitWith {["a radar position"] call _cancel};
private _config = createHashMap;
{_config set [_x, _settings get _x]} forEach keys _settings;
_config set ["id", _id];
_config set ["centre", _centre];
_config set ["radarPosition", _radarPositions select 0];
_config set ["radarPositions", _radarPositions];
_config set ["staticPositions", _positionsByCategory getOrDefault ["static", []]];
_config set ["mobilePositions", _positionsByCategory getOrDefault ["mobile", []]];
if (_exactMode) then {
    _config set ["radarAssignments", _assignmentsByCategory getOrDefault ["radar", []]];
    _config set ["staticAssignments", _assignmentsByCategory getOrDefault ["static", []]];
    _config set ["mobileAssignments", _assignmentsByCategory getOrDefault ["mobile", []]];
    _config set ["fighterAssignments", _assignmentsByCategory getOrDefault ["fighter", []]];
};

diag_log format [
    "[WMP DYNAMIC AA] ZEN placement '%1' submitting: radars=%2 static=%3 mobile=%4 fighters=%5 mode=%6.",
    _id, count _radarPositions, count (_config get "staticPositions"), count (_config get "mobilePositions"),
    _config getOrDefault ["fighterCount", 0], _config getOrDefault ["assetSelectionMode", "PROFILE"]
];
[_config] remoteExecCall ["Waldo_fnc_DynamicAACreate", 2];
["System submitted to the server for validation.", "INFO"] call _notify;

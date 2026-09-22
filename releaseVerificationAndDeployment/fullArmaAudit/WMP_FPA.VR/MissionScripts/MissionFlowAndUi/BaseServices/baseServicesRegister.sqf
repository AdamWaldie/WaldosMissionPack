/*
 * Author: WaldoTheWarfighter
 * Purpose: Registers or replaces one named network of service objects; an empty rows array removes it.
 * Locality / Authority: Server only. The server publishes a complete registry and owns 3D markers.
 * Repeat / JIP: Reusing an ID replaces old rows/markers and refreshes each client's ACE actions.
 * Arguments: 0 group ID <STRING>; 1 rows <ARRAY> of [object <OBJECT>, label <STRING>,
 * services <ARRAY of SAVE, HEAL, SPECTATE, TELEPORT>, icon <STRING>,
 * transition <STRING or ARRAY>, marker offset <ARRAY [x,y,z] optional>];
 * 2 group transition <STRING preset or ARRAY of key/value overrides> (default STANDARD).
 * Return Value: <BOOL> accepted.
 * Current callers: Mission-maker initServer.sqf and scripted base reconfiguration.
 * Example: ["HQ", [[radio1, "HQ", ["SAVE", "HEAL", "TELEPORT"]],
 *                    [radio2, "FOB", ["TELEPORT", "SPECTATE"]]], "TRAVEL"] call Waldo_fnc_BaseServicesRegister;
 */
params [["_id", "", [""]], ["_rows", [], [[]]], ["_transition", "STANDARD", ["", []]]];
if (!isServer || {isRemoteExecuted} || {_id isEqualTo ""}) exitWith {false};
if !(missionNamespace getVariable ["Waldo_SharedFeatureConfigReady", false]) exitWith {
    [_id, _rows, _transition] spawn {
        params ["_id", "_rows", "_transition"];
        waitUntil {sleep 0.1; missionNamespace getVariable ["Waldo_SharedFeatureConfigReady", false]};
        [_id, _rows, _transition] call Waldo_fnc_BaseServicesRegister;
    };
    true
};
if !(missionNamespace getVariable ["Waldo_BaseServices_Enable", false]) exitWith {false};
private _clean = [];
{
    if (_x isEqualType [] && {count _x >= 3}) then {
        _x params [["_object", objNull, [objNull]], ["_label", "", [""]], ["_services", [], [[]]], ["_icon", "\a3\ui_f\data\igui\cfg\simpletasks\types\Use_ca.paa", [""]], ["_rowTransition", "", ["", []]], ["_markerOffset", [], [[]]]];
        if (!isNull _object && {_label isNotEqualTo ""}) then {
            if (_icon isEqualTo "") then {_icon = "\a3\ui_f\data\igui\cfg\simpletasks\types\Use_ca.paa"};
            private _valid = (_services apply {toUpperANSI _x}) arrayIntersect ["SAVE", "HEAL", "SPECTATE", "TELEPORT"];
            if (count _markerOffset != 3 || {(_markerOffset findIf {!(_x isEqualType 0)}) >= 0}) then {
                // Place the glyph against the object's upper surface by default, not at a
                // fixed height above it. Mission makers can override this model-space point.
                private _bounds = boundingBoxReal _object;
                _markerOffset = [0, 0, ((_bounds select 1) select 2) - 0.02];
            };
            _clean pushBack [_object, _label, _valid, _icon, _rowTransition, _markerOffset];
        };
    };
} forEach _rows;
private _registry = +(missionNamespace getVariable ["Waldo_BaseServices_Registry", []]);
private _oldIndex = _registry findIf {(_x select 0) isEqualTo _id};
if (_oldIndex >= 0) then {
    private _oldRows = (_registry select _oldIndex) select 1;
    {[_id + "_" + netId (_x select 0)] call Waldo_fnc_Remove3DMarker} forEach _oldRows;
    _registry deleteAt _oldIndex;
};
if (_clean isNotEqualTo []) then {
    _registry pushBack [_id, _clean, _transition];
    {
        _x params ["_object", "_label", "_services", "_icon", "_rowTransition", "_markerOffset"];
        [_id + "_" + netId _object, _object, createHashMapFromArray [
            ["text", _label], ["icon", _icon], ["offset", _markerOffset], ["distance", 20]
        ]] call Waldo_fnc_Create3DMarker;
    } forEach _clean;
};
missionNamespace setVariable ["Waldo_BaseServices_Registry", _registry, true];
[_registry] remoteExecCall ["Waldo_fnc_BaseServicesSetupLocal", 0];
true

/*
 * Author: WaldoTheWarfighter
 * Set up or replace every object in one named base-service network. Use this
 * from initServer.sqf when a script manages the whole network. For an Eden
 * object's Init field, Waldo_fnc_BaseServicesRegisterNode needs less setup.
 *
 * Locality and authority: Call on the server. It publishes the complete network
 * and 3D markers to clients, including players who join later.
 * Repeat and JIP: Reusing an ID replaces its objects and refreshes ACE actions.
 * An empty object list removes the network.
 *
 * Arguments:
 * 0: network ID <STRING> - nonempty name shared by this network's objects.
 * 1: objects <ARRAY> - each entry is [object <OBJECT>, label <STRING>,
 *    services <ARRAY of SAVE/HEAL/SPECTATE/TELEPORT>, optional icon <STRING>,
 *    optional arrival transition <STRING or ARRAY>, optional marker offset
 *    <ARRAY [x,y,z]>]. The icon defaults to WMP's service icon. An empty
 *    transition uses the network preset; an empty offset uses the object surface.
 * 2: network transition <STRING or ARRAY> - optional; default STANDARD.
 * Return Value: <BOOL> - true when the server accepts or queues the network.
 * Example: In initServer.sqf with radio1 and radio2 named in Eden:
 * ["HQ", [[radio1, "HQ", ["SAVE", "HEAL", "TELEPORT"]],
 *         [radio2, "FOB", ["TELEPORT", "SPECTATE"]]], "TRAVEL"]
 *     call Waldo_fnc_BaseServicesRegister;
 * Result: Players can travel between the radios; the HQ also saves loadouts
 * and heals, while the FOB offers ACE spectator.
 * Current callers: Mission-maker initServer.sqf and scripted base updates.
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

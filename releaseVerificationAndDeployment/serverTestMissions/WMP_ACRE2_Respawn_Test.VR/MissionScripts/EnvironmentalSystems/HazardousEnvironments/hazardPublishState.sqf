/*
 * Author: WaldoTheWarfighter, Val
 * Publishes one ordered, replaceable hazardous-environment snapshot from the authoritative server.
 *
 * Enablement and the complete zone registry travel in the same payload, preventing dedicated and
 * JIP clients from starting against stale or missing zones. Networked profiles may reference
 * callbacks by missionNamespace function-name STRING. Raw CODE callbacks remain server-local and
 * are omitted from the transported copy because executable code is not safe JIP state.
 *
 * Arguments: None.
 * Return Value: BOOLEAN - true on the server.
 * Example: [] call Waldo_fnc_HazardPublishState;
 * Current callers: register/remove zone and authoritative runtime control.
 */

if !(isServer) exitWith {false};
private _zones = missionNamespace getVariable ["Waldo_Hazard_Zones", []];
private _networkZones = [];
{
    _x params ["_key", "_area", "_profile"];
    private _networkProfile = createHashMap;
    {
        private _value = _profile get _x;
        if (_x in ["onEnter", "onExit", "onTick"] && {_value isEqualType {}}) then {
            diag_log format ["[WMP HAZARD] Zone '%1' callback '%2' is local CODE and was omitted from the network snapshot; use a function-name STRING for dedicated clients.", _key, _x];
        } else {
            _networkProfile set [_x, _value];
        };
    } forEach keys _profile;
    _networkZones pushBack [_key, _area, _networkProfile];
} forEach _zones;
private _enabled = missionNamespace getVariable ["Waldo_Hazard_Enable", false] && {count _zones > 0};
[_enabled, _networkZones] remoteExecCall ["Waldo_fnc_HazardReceiveSnapshot", 0, "Waldo_Hazard_RuntimeSnapshot"];
diag_log format ["[WMP HAZARD] Published ordered snapshot: enabled=%1 zones=%2.", _enabled, count _networkZones];
true

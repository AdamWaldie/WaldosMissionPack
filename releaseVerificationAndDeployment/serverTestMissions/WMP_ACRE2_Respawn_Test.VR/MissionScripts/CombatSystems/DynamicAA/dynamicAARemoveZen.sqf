/*
 * Author: WaldoTheWarfighter
 * Removes the Dynamic AA system nearest to a placed ZEN module.
 *
 * Arguments:
 * 0: modulePosition <ARRAY>
 *
 * Return Value:
 * Nothing
 */

params [["_modulePos", [], [[]]]];
if !(hasInterface) exitWith {};
private _systems = missionNamespace getVariable ["Waldo_DynamicAA_PublicSystems", []];
if (count _systems == 0) exitWith {systemChat "[WMP] No Dynamic AA systems are active."};
private _nearest = _systems select 0;
{
    if ((_x select 1) distance2D _modulePos < (_nearest select 1) distance2D _modulePos) then {_nearest = _x};
} forEach _systems;
_nearest params ["_id"];
private _displayName = _nearest param [8, _id];
[
    format ["Remove Dynamic AA: %1", _displayName],
    [["CHECKBOX", [format ["Delete %1's assets", _displayName], "Clear this to leave its spawned assets in place but disabled."], true]],
    {
        params ["_values", "_id"];
        [_id, _values select 0] remoteExecCall ["Waldo_fnc_DynamicAADestroy", 2];
    },
    {},
    _id
] call zen_dialog_fnc_create;

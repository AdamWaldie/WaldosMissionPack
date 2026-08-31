/*
 * Author: WaldoTheWarfighter
 * Removes an Economy object from one typed runtime registry.
 *
 * Locality/authority: server only. Registry membership/revision are published; a listen server
 * requests its local reconciliation directly. Repeat/JIP behaviour: repeat-safe and publishes only
 * when logical membership changes.
 *
 * Arguments:
 * 0: _object <OBJECT> - object to remove (default: objNull)
 * 1: _key <STRING> - typed registry key (default: "")
 *
 * Return Value: BOOL - true when membership changed.
 * Current callers: runtime-object Deleted handler and subsystem cleanup paths.
 * Example: [_terminal, "PURCHASE_TERMINALS"] call Waldo_fnc_EcoCore_unregisterRuntimeObject;
 */
params [["_object", objNull], ["_key", ""]];
if (!isServer || {_key == ""}) exitWith {false};

private _variable = format ["WaldoEcoCore_Runtime_%1", toUpper _key];
private _objects = +(missionNamespace getVariable [_variable, []]);
private _clean = _objects select {!isNull _x && {_x != _object}};
if ((count _clean) == (count _objects)) exitWith {false};
missionNamespace setVariable [_variable, _clean, true];
missionNamespace setVariable [
    "WaldoEcoCore_RuntimeRegistryRevision",
    (missionNamespace getVariable ["WaldoEcoCore_RuntimeRegistryRevision", 0]) + 1,
    true
];
if (hasInterface) then {
    [] call Waldo_fnc_EcoCore_requestLocalWorldActionRefresh;
};
true

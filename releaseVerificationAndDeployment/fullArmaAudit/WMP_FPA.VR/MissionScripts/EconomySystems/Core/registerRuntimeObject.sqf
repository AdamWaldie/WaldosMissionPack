/*
 * Author: WaldoTheWarfighter
 * Registers a live Economy object in a typed, JIP-safe runtime registry.
 *
 * Locality/authority: server only. Registry membership/revision are public authoritative state;
 * a listen server requests its local action refresh directly because publication does not replay to
 * the publishing machine. Repeat/JIP behaviour: repeat-safe; deletion unregisters every bound key.
 *
 * Arguments:
 * 0: _object <OBJECT> - Economy runtime object (default: objNull)
 * 1: _key <STRING> - CRATES, RESEARCH_CENTERS, CONSTRUCTION_VEHICLES,
 *                    PURCHASE_TERMINALS or BUILDINGS (default: "")
 *
 * Return Value: BOOL - true only when the object was newly added.
 * Current callers: Economy creation/registration functions and recovery discovery.
 * Example: [_crate, "CRATES"] call Waldo_fnc_EcoCore_registerRuntimeObject;
 */
params [["_object", objNull], ["_key", ""]];
if (!isServer || {isNull _object} || {_key == ""}) exitWith {false};

_key = toUpper _key;
private _variable = format ["WaldoEcoCore_Runtime_%1", _key];
private _objects = +(missionNamespace getVariable [_variable, []]);
private _clean = _objects select {!isNull _x};
private _added = (_clean pushBackUnique _object) >= 0;
if (_added || {(count _clean) != (count _objects)}) then {
    missionNamespace setVariable [_variable, _clean, true];
    missionNamespace setVariable [
        "WaldoEcoCore_RuntimeRegistryRevision",
        (missionNamespace getVariable ["WaldoEcoCore_RuntimeRegistryRevision", 0]) + 1,
        true
    ];
    if (hasInterface) then {
        [] call Waldo_fnc_EcoCore_requestLocalWorldActionRefresh;
    };
};

private _registeredKeys = +(_object getVariable ["WaldoEcoCore_RuntimeRegistryKeys", []]);
if ((_registeredKeys pushBackUnique _key) >= 0) then {
    _object setVariable ["WaldoEcoCore_RuntimeRegistryKeys", _registeredKeys, false];
};
if (!(_object getVariable ["WaldoEcoCore_RuntimeDeleteHandler", false])) then {
    _object setVariable ["WaldoEcoCore_RuntimeDeleteHandler", true, false];
    _object addEventHandler ["Deleted", {
        params ["_entity"];
        {
            [_entity, _x] call Waldo_fnc_EcoCore_unregisterRuntimeObject;
        } forEach (_entity getVariable ["WaldoEcoCore_RuntimeRegistryKeys", []]);
    }];
};
_added
